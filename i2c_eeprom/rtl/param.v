//i2c时钟参数
`define  SCL_PERIOD  250
`define  SCL_HALF    125
`define  LOW_HLAF    65 
`define  HIGH_HALF   180

//i2c命令参数
`define CMD_START   4'b0001
`define CMD_WRITE   4'b0010
`define CMD_READ    4'b0100
`define CMD_STOP    4'b1000

//定义eeprom读写模式
//`define BYTE_WRITE      //字节写
`define PAGE_WRITE      //页写

//`define RANDOM_READ     //随机地址读    每次写1字节
`define SEQU_READ       //顺序地址读    每次读16字节

`ifdef  BYTE_WRITE
    `define WR_BYTE 3
`elsif  PAGE_WRITE
    `define WR_BYTE 18
`endif 

`ifdef  RANDOM_READ
    `define RD_BYTE 4
`elsif  SEQU_READ
    `define RD_BYTE 19
`endif 


//I2C外设地址参数定义
`define     I2C_ADR 6'b1010_00  //6'b1010_00xy x：Block地址 y：读写控制位 WR_BIT/RD_BIT
`define     WR_BIT  1'b0    //bit0
`define     RD_BIT  1'b1    //bit0


//串口参数定义

`define  BAUD_9600   5208
`define  BAUD_19200  2604
`define  BAUD_38400  1302
`define  BAUD_115200 434

`define STOP_BIT  1'b1
`define START_BIT 1'b0


