module controler #(parameter WR_LEN = 16,RD_LEN = 8)
(
    input               clk     ,
    input               rst_n   ,

    //user port
    input       [7:0]   din     ,
    input               din_vld ,
    input               rd_en   ,
    output      [7:0]   dout    ,
    output              dout_vld,
    input               tx_busy ,//串口发送忙标志
    //mem port
    output              i2c_scl ,
    inout               i2c_sda 
);
    
 //信号定义

   wire             req             ; 
   wire     [3:0]   cmd             ; 
   wire     [7:0]   wr_data         ; 
   wire     [7:0]   rd_data         ; 
   wire             done            ; 
   wire             i2c_sda_i       ; 
   wire             i2c_sda_o       ; 
   wire             i2c_sda_oe      ; 
    

//模块例化

    eeprom_rw #(.WR_LEN(WR_LEN),.RD_LEN(RD_LEN))u_rw_ctrl(
    /*input               */.clk     (clk       ),
    /*input               */.rst_n   (rst_n     ),
    
    /*input       [7:0]   */.din     (din       ),
    /*input               */.din_vld (din_vld   ),
    /*input               */.rd_en   (rd_en     ),
    /*output      [7:0]   */.dout    (dout      ),//控制器输出数据
    /*output              */.dout_vld(dout_vld  ),
    /*input               */.busy    (tx_busy   ),
    /*output              */.req     (req       ),
    /*output      [3:0]   */.cmd     (cmd       ),
    /*output      [7:0]   */.wr_data (wr_data   ),
    /*input       [7:0]   */.rd_data (rd_data   ),
    /*input               */.done    (done      ) //传输完成标志
    );

    i2c_master u_i2c(
    /*input               */.clk         (clk       ),
    /*input               */.rst_n       (rst_n     ),

    /*input               */.req         (req       ),
    /*input       [3:0]   */.cmd         (cmd       ),
    /*input       [7:0]   */.din         (wr_data   ),

    /*output      [7:0]   */.dout        (rd_data   ),
    /*output              */.done        (done      ),

    /*output              */.i2c_scl     (i2c_scl   ),
    /*input               */.i2c_sda_i   (i2c_sda_i ),
    /*output              */.i2c_sda_o   (i2c_sda_o ),
    /*output              */.i2c_sda_oe  (i2c_sda_oe)   
    );

    assign i2c_sda = i2c_sda_oe?i2c_sda_o:1'bz;
    assign i2c_sda_i = i2c_sda;


 endmodule 

