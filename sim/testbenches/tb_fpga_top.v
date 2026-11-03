`timescale 1ns/1ps
module tb_fpga;
  reg clk=0, btn=1, sw0=0; wire [15:0] led;
  always #5 clk=~clk;
  fpga_top u(.clk(clk),.btn_rst(btn),.sw0(sw0),.led(led));
  initial begin
    repeat(5) @(posedge clk); btn=0;          // release reset button
    repeat(200) @(posedge clk);
    sw0=0; #1 $display("sw0=0  led=%b  done=%b  cycles=%0d", led, led[15], led[14:0]);
    sw0=1; #1 $display("sw0=1  led=%b  done=%b  x30=%0d",    led, led[15], led[14:0]);
    $finish;
  end
endmodule
