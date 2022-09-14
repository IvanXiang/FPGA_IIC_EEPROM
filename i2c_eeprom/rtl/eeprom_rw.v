`include "param.v"

module eeprom_rw #(parameter WR_LEN = 3,RD_LEN = 4)(
    input               clk     ,
    input               rst_n   ,
    
    input       [7:0]   din     ,
    input               din_vld ,
    input               rd_en   ,
    output      [7:0]   dout    ,//控制器输出数据
    output              dout_vld,
    input               busy    ,

    output              req     ,
    output      [3:0]   cmd     ,
    output      [7:0]   wr_data ,
    input       [7:0]   rd_data ,
    input               done     //传输完成标志
  
);


//状态机参数
    localparam      IDLE    = 6'b00_0001    ,
                    WR_REQ  = 6'b00_0010    ,//写传输 发送请求、命令、数据
                    WAIT_WR = 6'b00_0100    ,//等待一个字节传完
                    RD_REQ  = 6'b00_1000    ,//读传输 发送请求、命令、数据
                    WAIT_RD = 6'b01_0000    ,//等待一个自己传完
                    DONE    = 6'b10_0000    ;//一次读或写完成
//信号定义
    reg     [5:0]   state_c         ;
    reg     [5:0]   state_n         ;

    reg     [7:0]   cnt_byte        ;//数据传输 字节计数器
    wire            add_cnt_byte    ;
    wire            end_cnt_byte    ;

    reg             tx_req          ;//请求
    reg     [3:0]   tx_cmd          ;
    reg     [7:0]   tx_data         ;
    
    reg     [8:0]   wr_addr         ;//写eeprom地址
    reg     [8:0]   rd_addr         ;//读eeprom地址
    
    wire            wfifo_rd        ; 
    wire            wfifo_wr        ;
    wire            wfifo_empty     ;
    wire            wfifo_full      ;
    wire    [7:0]   wfifo_qout      ;
    wire    [5:0]   wfifo_usedw     ;
   
    wire            rfifo_rd        ;
    wire            rfifo_wr        ;
    wire            rfifo_empty     ;
    wire            rfifo_full      ;
    wire    [7:0]   rfifo_qout      ;
    wire    [5:0]   rfifo_usedw     ;

    reg             rd_flag         ;
    reg     [7:0]   user_data       ;
    reg             user_data_vld   ;

    wire            idle2wr_req     ; 
    wire            wr_req2wait_wr  ;
    wire            wait_wr2wr_req  ;
    wire            wait_wr2done    ;
    wire            idle2rd_req     ;
    wire            rd_req2wait_rd  ;
    wire            wait_rd2rd_req  ;
    wire            wait_rd2done    ;
    wire            done2idle       ;

//状态机设计
    always @(posedge clk or negedge rst_n) begin 
        if (rst_n==0) begin
            state_c <= IDLE ;
        end
        else begin
            state_c <= state_n;
       end
    end
    
    always @(*) begin 
        case(state_c)  
            IDLE :begin
                if(idle2wr_req)
                    state_n = WR_REQ ;
                else if(idle2rd_req)
                    state_n = RD_REQ ;
                else 
                    state_n = state_c ;
            end
            WR_REQ :begin
                if(wr_req2wait_wr)
                    state_n = WAIT_WR ;
                else 
                    state_n = state_c ;
            end
            WAIT_WR :begin
                if(wait_wr2wr_req)
                    state_n = WR_REQ ;
                else if(wait_wr2done)
                    state_n = DONE ;
                else 
                    state_n = state_c ;
            end
            RD_REQ :begin
                if(rd_req2wait_rd)
                    state_n = WAIT_RD ;
                else 
                    state_n = state_c ;
            end
            WAIT_RD :begin
                if(wait_rd2rd_req)
                    state_n = RD_REQ ;
                else if(wait_rd2done)
                    state_n = DONE ;
                else 
                    state_n = state_c ;
            end
            DONE :begin
                if(done2idle)
                    state_n = IDLE ;
                else 
                    state_n = state_c ;
            end
            default : state_n = IDLE ;
        endcase
    end
    
    assign idle2wr_req      = state_c==IDLE     && (wfifo_usedw > WR_LEN-2);
    assign wr_req2wait_wr   = state_c==WR_REQ   && (1'b1);
    assign wait_wr2wr_req   = state_c==WAIT_WR  && (done & cnt_byte < WR_LEN-1);
    assign wait_wr2done     = state_c==WAIT_WR  && (end_cnt_byte);
    assign idle2rd_req      = state_c==IDLE     && (rd_en);
    assign rd_req2wait_rd   = state_c==RD_REQ   && (1'b1);
    assign wait_rd2rd_req   = state_c==WAIT_RD  && (done & cnt_byte < RD_LEN-1);
    assign wait_rd2done     = state_c==WAIT_RD  && (end_cnt_byte);
    assign done2idle        = state_c==DONE     && (1'b1);
    
//cnt_byte  
    always @(posedge clk or negedge rst_n) begin 
        if (rst_n==0) begin
            cnt_byte <= 0; 
        end
        else if(add_cnt_byte) begin
            if(end_cnt_byte)
                cnt_byte <= 0; 
            else
                cnt_byte <= cnt_byte+1 ;
       end
    end
    assign add_cnt_byte = (state_c==WAIT_WR | state_c==WAIT_RD) & done;
    assign end_cnt_byte = add_cnt_byte  && cnt_byte == ((state_c==WAIT_WR)?
                                                        (WR_LEN-1):(RD_LEN-1));
//输出

    always  @(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            TX(1'b0,4'd0,8'd0);
        end
        else if(state_c==WR_REQ)begin
            case(cnt_byte)
                0           :TX(1'b1,{`CMD_START | `CMD_WRITE},{`I2C_ADR,wr_addr[8],`WR_BIT});//发起始位、写控制字
                1           :TX(1'b1,`CMD_WRITE,wr_addr[7:0]);   //发 写地址
                WR_LEN-1  :TX(1'b1,{`CMD_WRITE | `CMD_STOP},wfifo_qout);  //最后一个字节时 发数据、停止位
                default     :TX(1'b1,`CMD_WRITE,wfifo_qout);    //中间发数据（如果有）
            endcase 
        end
        else if(state_c==RD_REQ)begin
            case(cnt_byte)
                0           :TX(1'b1,{`CMD_START | `CMD_WRITE},{`I2C_ADR,rd_addr[8],`WR_BIT});//发起始位、写控制字
                1           :TX(1'b1,`CMD_WRITE,rd_addr[7:0]);   //发 读地址
                2           :TX(1'b1,{`CMD_START | `CMD_WRITE},{`I2C_ADR,rd_addr[8],`RD_BIT});//发起始位、读控制字
                RD_LEN-1    :TX(1'b1,{`CMD_READ | `CMD_STOP},0);  //最后一个字节时 读数据、发停止位
                default     :TX(1'b1,`CMD_READ,0);    //中间读数据（如果有）
            endcase 
        end
        else begin 
             TX(1'b0,tx_cmd,tx_data);
        end 
    end
//用task发送请求、命令、数据（地址+数据）
    task TX;   
        input                   req     ;
        input       [3:0]       command ;
        input       [7:0]       data    ;
        begin 
            tx_req  = req;
            tx_cmd  = command;
            tx_data = data;
        end 
    endtask 

//wr_addr   rd_addr
    always  @(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            wr_addr <= 0;
        end
        else if(wait_wr2done)begin
            wr_addr <= wr_addr + WR_LEN-2;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            rd_addr <= 0;
        end
        else if(wait_rd2done)begin
            rd_addr <= rd_addr + RD_LEN - 3;
        end
    end

//rd_flag
    always  @(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            rd_flag <= 1'b0;
        end
        else if(~rfifo_empty)begin
            rd_flag <= 1'b1;
        end
        else begin 
            rd_flag <= 1'b0;
        end 
    end

//user_data user_data_vld
    always  @(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            user_data <= 0;
            user_data_vld <= 0;
        end
        else begin
            user_data <= rfifo_qout;
            user_data_vld <= rfifo_rd;
        end
    end

  
//输出

    assign req     = tx_req ; 
    assign cmd     = tx_cmd ; 
    assign wr_data = tx_data; 

    assign dout    = user_data;//控制器输出数据
    assign dout_vld= user_data_vld;

//fifo例化

wrfifo	u_wrfifo (
	.aclr   (~rst_n     ),
	.clock  (clk        ),
	.data   (din        ),
	.rdreq  (wfifo_rd   ),
	.wrreq  (wfifo_wr   ),
	.empty  (wfifo_empty),
	.full   (wfifo_full ),
	.q      (wfifo_qout ),
	.usedw  (wfifo_usedw)
	);

    assign wfifo_rd = state_c==WAIT_WR && done && cnt_byte > 1;
    assign wfifo_wr = ~wfifo_full & din_vld;

rdfifo	u_rdfifo (
	.aclr   (~rst_n     ),
	.clock  (clk        ),
	.data   (rd_data    ),
	.rdreq  (rfifo_rd   ),
	.wrreq  (rfifo_wr   ),
	.empty  (rfifo_empty),
	.full   (rfifo_full ),
	.q      (rfifo_qout ),
	.usedw  (rfifo_usedw)
	);

    assign rfifo_wr = ~rfifo_full && state_c==WAIT_RD && cnt_byte > 2 && done;
    assign rfifo_rd = rd_flag && ~busy;

endmodule

