`include "param.v"
module uart_tx (
    input               clk         ,
    input               rst_n       ,
    input       [1:0]   baud_sel    ,//选择波特率
    input               tx_byte_vld ,//相当于一个发送请求
    input       [7:0]   tx_byte     ,
    output              busy        ,//忙状态指示  握手信号
    output              tx_dout     
);

//信号定义

    reg     [12:0]          cnt_baud    ;//波特率计数器
    wire                    add_cnt_baud;
    wire                    end_cnt_baud;
    reg                     flag        ;

    reg     [3:0]           cnt_bit     ;//bit计数器
    wire                    add_cnt_bit ;
    wire                    end_cnt_bit ;

    reg     [12:0]          baud        ;
    reg     [9:0]           tx_data     ;//需要发送的数据 起始位 + 数据 + 停止位

//计数器
    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt_baud <= 0;
        end 
        else if(add_cnt_baud)begin 
            if(end_cnt_baud)begin 
                cnt_baud <= 0;
            end
            else begin 
                cnt_baud <= cnt_baud + 1;
            end 
        end
    end 
    assign add_cnt_baud = flag;
    assign end_cnt_baud = add_cnt_baud && cnt_baud == baud-1;
                                            
    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt_bit <= 0;
        end 
        else if(add_cnt_bit)begin 
            if(end_cnt_bit)begin 
                cnt_bit <= 0;
            end
            else begin 
                cnt_bit <= cnt_bit + 1;
            end 
        end
    end 
    assign add_cnt_bit = end_cnt_baud;
    assign end_cnt_bit = add_cnt_bit && (cnt_bit == 10-1);//10bit发送完或者 停止接收

//flag
    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            flag <= 0;
        end 
        else if(tx_byte_vld)begin 
            flag <= 1'b1;
        end 
        else if(end_cnt_bit)begin 
            flag <= 1'b0;
        end 
    end

//baud
    always @(*)begin 
        case (baud_sel)
            0:baud = `BAUD_9600  ;
            1:baud = `BAUD_19200 ;
            2:baud = `BAUD_38400 ;
            3:baud = `BAUD_115200; 
            default:baud = `BAUD_9600  ;
        endcase
    end

//tx_data
    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            tx_data <= 0;
        end 
        else if(tx_byte_vld)begin //收到发送请求时，把数据位和起始位、停止位拼接
            tx_data <= {`STOP_BIT,tx_byte,`START_BIT};
        end 
        /*
        else if(add_cnt_baud && end_cnt_bit)begin 
            tx_data <= tx_data >> 1;
        end 
        */
    end

//输出
//  assign tx_dout = tx_data[0];
    assign tx_dout = add_cnt_baud?tx_data[cnt_bit]:1'b1;
    
    assign busy = tx_byte_vld | add_cnt_baud;
    
/*    
    assign busy = add_cnt_baud;


    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            busy <= 0;
        end 
        else if(tx_byte_vld)begin 
            busy <= 1'b1;
        end 
        else if(end_cnt_bit)begin 
            busy <= 1'b0;
        end 
    end
*/

endmodule   
