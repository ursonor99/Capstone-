`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2021 08:44:54 PM
// Design Name: 
// Module Name: loopback_uart_fifo_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module loopback_uart_fifo_tb(

    );
   // Testbench uses a 10 MHz clock
  // Want to interface to 115200 baud UART
  // 10000000 / 115200 = 87 Clocks Per Bit.
  parameter c_CLOCK_PERIOD_NS = 4;
  parameter c_CLKS_PER_BIT    = 4;
  parameter c_BIT_PERIOD      = 16;
   
  reg r_Clock = 0;
  reg r_Tx_DV = 0;
  reg [7:0] r_Tx_Byte = 0 ;
  reg r_Rx_Serial = 0;
  reg r_read_flag = 0;
  reg r_Reset = 0;
  reg r_Tx_Send  = 0;
  
  wire w_Tx_Done;
  wire [7:0] w_Rx_Byte;
  wire [7:0] w_Rx_Byte_fifo;
  wire w_Tx_Byte;
  wire [2:0] state;
  //wire [7:0] o_byte;
  // Takes in input byte and serializes it 
  task UART_WRITE_BYTE;
    input [7:0] i_Data;
    integer     ii;
    begin
       
      // Send Start Bit
      r_Rx_Serial <= 1'b0;
      #(c_BIT_PERIOD);
       
       
      // Send Data Byte
      for (ii=0; ii<8; ii=ii+1)
        begin
          r_Rx_Serial <= i_Data[ii];
          #(c_BIT_PERIOD);
        end
       
      // Send Stop Bit
      r_Rx_Serial <= 1'b1;
      #(c_BIT_PERIOD);
     end
  endtask // UART_WRITE_BYTE
   
   
  uart_fifo_rx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_RX_INST
    (.i_Clock(r_Clock),
     .i_Reset(r_Reset),
     //.i_Rx_Serial(r_Rx_Serial),
     .i_Rx_Serial(w_Tx_Byte),
     .o_Rx_DV(),
     .o_Rx_Byte(w_Rx_Byte_fifo),
     .i_Read_Flag(r_read_flag),
     .r_Rx_Byte(w_Rx_Byte),
     .r_SM_Main(state)
     );
   
  uart_fifo_tx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_TX_INST
    (.i_Clock(r_Clock),
     .i_Reset(r_Reset),
     .i_Tx_Send(r_Tx_Send),
     .i_Tx_DV(r_Tx_DV),
     .i_Tx_Byte(r_Tx_Byte),
     .o_Tx_Active(),
     .o_Tx_Serial(w_Tx_Byte),
     .o_Tx_Done(w_Tx_Done)
     //.o_Tx_Byte(o_byte)
     //.r_SM_Main(state)
     );
 
   
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
 
   
  // Main Testing:
  initial
    begin
      r_Rx_Serial <= 1'b1;
      r_Reset<=1'b1;
      r_Tx_Send<=1'b0;
      //Tell UART to send a command (exercise Tx)       
      @(posedge r_Clock);
      r_Reset <=1'b0;
      r_Tx_DV <= 1'b1;
      
      r_Tx_Byte <= 8'h01;
      
      r_Tx_Send <=1;
      //#10
      @(posedge r_Clock);
      r_Tx_DV <= 1'b0;
      @(posedge w_Tx_Done);
      
      
      //Send a command to the UART (exercise Rx)
      @(posedge r_Clock);
      UART_WRITE_BYTE(8'h04);
      
      @(posedge r_Clock);
             
      // Check that the correct command was received
      #20;
      if (w_Rx_Byte == 8'h05)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
      
                 
       //Tell UART to send a command (exercise Tx)
      @(posedge r_Clock);
      r_Tx_DV <= 1'b1;
      r_Tx_Byte <= 8'h02;
      
      //#10
      @(posedge r_Clock);
      r_Tx_DV <= 1'b0;
      //r_Tx_Send <=0;
      @(posedge w_Tx_Done);
      
      
      //Send a command to the UART (exercise Rx)
      @(posedge r_Clock);
      UART_WRITE_BYTE(8'hC9);
      r_read_flag <=1;
      @(posedge r_Clock);
      r_read_flag <=0;       
      // Check that the correct command was received
      #40;
      if (w_Rx_Byte == 8'hC9)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
      //r_Tx_Send <=1;               
      //$finish;
    end
    
endmodule
