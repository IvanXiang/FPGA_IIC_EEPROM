`include "param.v"

module uart_rx (
    input               clk         ,
    input               rst_n       ,
    input       [1:0]   baud_sel    ,//选择波特率
    input               rx_din      ,
    output      [7:0]   rx_byte     ,
    output              rx_byte_vld 
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
    reg     [1:0]           din_r       ;//同步  打拍 
    wire                    n_edge      ;//下降沿检测

    reg     [9:0]           rx_data     ;

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
    assign end_cnt_bit = add_cnt_bit && (cnt_bit == 10-1 || rx_data[0] == 1'b1);//10bit接收完或者 起始位接收出错 停止接收

//flag
    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            flag <= 0;
        end 
        else if(flag == 1'b0 && n_edge)begin 
flag <= 1'b1;
        end             
        else if(flag && end_cnt_bit)begin 
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

//同步打拍
    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            din_r <= 0;
        end 
        else begin 
            din_r <= {din_r[0],rx_din};
        end 
    end

    assign n_edge = ~din_r[0] & din_r[1];

//rx_data
    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            rx_data <= 0;
        end 
        else if(add_cnt_baud && cnt_baud == (baud>>1))begin 
            //rx_data <= {rx_din,rx_data[9:1]};//右移
            rx_data[cnt_bit] <= rx_din;
        end 
    end

//输出
    assign rx_byte = rx_data[8:1];
    assign rx_byte_vld = end_cnt_bit;

endmodule   
