`include "param.v"

module i2c_eeprom(
    input               clk         ,
    input               rst_n       ,

    //uart
    input               uart_rxd    ,
    output              uart_txd    ,

    //key
    input               key_in      ,

    //eeprom
    output              i2c_scl     ,
    inout               i2c_sda     
);

//信号定义
    wire                key_out     ;
    wire    [7:0]       rx_byte     ;
    wire                rx_byte_vld ;
    wire    [7:0]       tx_data     ; 
    wire                tx_data_vld ;
    wire                tx_busy     ;

    wire    [1:0]       baud_sel    ;
    assign baud_sel = 3;

	
//模块例化

key_debounce #(.KEY_W(1)) u_key(
	/*input					    */.clk		(clk	    ),
	/*input					    */.rst_n	(rst_n      ),
	/*input		[KEY_W-1:0]	    */.key_in 	(key_in     ),
	/*output	reg	[KEY_W-1:0]	*/.key_out	(key_out    ) 
);


uart_rx u_rx(
    /*input               */.clk         (clk           ),
    /*input               */.rst_n       (rst_n         ),
    /*input       [1:0]   */.baud_sel    (baud_sel      ),//选择波特率
    /*input               */.rx_din      (uart_rxd      ),
    /*output      [7:0]   */.rx_byte     (rx_byte       ),
    /*output              */.rx_byte_vld (rx_byte_vld   )
);

controler #(.WR_LEN(`WR_BYTE),.RD_LEN(`RD_BYTE)) u_mem_ctrl(
    /*input               */.clk     (clk           ),
    /*input               */.rst_n   (rst_n         ),

    //user port
    /*input       [7:0]   */.din     (rx_byte       ),
    /*input               */.din_vld (rx_byte_vld   ),
    /*input               */.rd_en   (key_out       ),
    /*output      [7:0]   */.dout    (tx_data       ),
    /*output              */.dout_vld(tx_data_vld   ),
    /*input               */.tx_busy (tx_busy       ),//串口发送忙标志
    //mem port
    /*output              */.i2c_scl (i2c_scl       ),
    /*inout               */.i2c_sda (i2c_sda       )
);

uart_tx u_tx(
    /*input               */.clk         (clk           ),
    /*input               */.rst_n       (rst_n         ),
    /*input       [1:0]   */.baud_sel    (baud_sel      ),//选择波特率
    /*input               */.tx_byte_vld (tx_data_vld   ),//相当于一个发送请求
    /*input       [7:0]   */.tx_byte     (tx_data       ),
    /*output              */.busy        (tx_busy       ),//忙状态指示  握手信号
    /*output              */.tx_dout     (uart_txd      )
);


endmodule

