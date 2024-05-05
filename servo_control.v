module servo_control (
  input clk,
  input rst_n,
  input [2:0] servo_id,
  input [11:0] pwm_value,
  input [1:0] time_value,
  output reg tx_busy
);

parameter BAUD_RATE = 115200; // 波特率
parameter CLK_FRE = 50; // 时钟频率(MHz)

localparam                       IDLE =  0;
localparam                       SEND =  1;   
localparam                       WAIT =  2;   //wait 1 second and send uart received data
reg[7:0]                         tx_data;
reg[7:0]                         tx_str;
reg                              tx_data_valid;
wire                             tx_data_ready;
reg[7:0]                         tx_cnt;
reg[31:0]                        wait_cnt;
reg[3:0]                         state;

//function：将数字转换为字符串
//# + servo_id + pwm_value + time_value + "!" -> str
function reg [7:0] int_to_ascii(input reg [3:0] digit);
  reg [7:0] ascii_char;
  begin
    case (digit)
      4'd0: ascii_char = "0";
      4'd1: ascii_char = "1";
      4'd2: ascii_char = "2";
      4'd3: ascii_char = "3";
      4'd4: ascii_char = "4";
      4'd5: ascii_char = "5";
      4'd6: ascii_char = "6";
      4'd7: ascii_char = "7";
      4'd8: ascii_char = "8";
      4'd9: ascii_char = "9";
      default: ascii_char = " "; // Or handle the case differently
    endcase
  end
  int_to_ascii = ascii_char;
endfunction

function reg [95:0] int_to_string(input reg [31:0] value);
  reg [7:0] str[11:0]; // Array to store individual digit characters
  integer i;
  begin
    for (i = 0; i < 12; i = i + 1) begin
      str[i] = int_to_ascii(value % 10); // Extract and convert each digit
      value = value / 10; // Shift the value for next digit extraction
    end
    int_to_string = {str[11], str[10], str[9], str[8], str[7], str[6], str[5], str[4], str[3], str[2], str[1], str[0]}; // Concatenate digits
  end
endfunction

reg [23:0] servo_id_str;
reg [31:0] pwm_value_str;
reg [31:0] time_value_str;

initial begin
	servo_id_str = int_to_string(servo_id);
	pwm_value_str = int_to_string(pwm_value);
	time_value_str = int_to_string(time_value);

    tx_data_valid = 1'b1;
end

// reg [127:0] str;
// str = {"#", servo_id_str, "P" ,pwm_value_str,"T", time_value_str, "!"}

always@(*)
begin
	case(tx_cnt)  //#000P0500T1000!
		8'd0 :  tx_str <= "#";
		8'd1 :  tx_str <= servo_id_str[23:16];
		8'd2 :  tx_str <= servo_id_str[15:8];
		8'd3 :  tx_str <= servo_id_str[7:0];
		8'd4 :  tx_str <= "P";
		8'd5 :  tx_str <= pwm_value_str[31:24];
		8'd6 :  tx_str <= pwm_value_str[23:16];
		8'd7 :  tx_str <= pwm_value_str[15:8];
		8'd8 :  tx_str <= pwm_value_str[7:0];
		8'd9 :  tx_str <= "T";
		8'd10:  tx_str <= time_value_str[31:24];
		8'd11:  tx_str <= time_value_str[23:16];
		8'd12:  tx_str <= time_value_str[15:8];
		8'd13:  tx_str <= time_value_str[7:0];
		8'd14:  tx_str <= "!";
		default:tx_str <= 8'd0;
	endcase
end

always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
	begin
		wait_cnt <= 32'd0;
		tx_data <= 8'd0;
		state <= IDLE;
		tx_cnt <= 8'd0;
		tx_data_valid <= 1'b0;
	end

    else 
    case(state)
        IDLE:
			state <= SEND;
		SEND:
		begin
			wait_cnt <= 32'd0;
			tx_data <= tx_str;

			if(tx_data_valid == 1'b1 && tx_data_ready == 1'b1 && tx_cnt < 8'd14)//Send 14 bytes data
			begin
				tx_cnt <= tx_cnt + 8'd1; //Send data counter
			end
			else if(tx_data_valid && tx_data_ready)//last byte sent is complete
			begin
				tx_cnt <= 8'd0;
				tx_data_valid <= 1'b0;
				state <= WAIT;
			end
			else if(~tx_data_valid)
			begin
				tx_data_valid <= 1'b1;
			end
		end
		WAIT:
		begin
            state <= WAIT;
		// 	wait_cnt <= wait_cnt + 32'd1;

		// 	if(rx_data_valid == 1'b1)
		// 	begin
		// 		tx_data_valid <= 1'b1;
		// 		tx_data <= rx_data;   // send uart received data
		// 	end
		// 	else if(tx_data_valid && tx_data_ready)
		// 	begin
		// 		tx_data_valid <= 1'b0;
		// 	end
		// 	else if(wait_cnt >= CLK_FRE * 10_000_000) // wait for 1 second
		// 		state <= SEND;
		end
		default:
			state <= IDLE;
    endcase
end


uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(BAUD_RATE)
) uart_tx_inst
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.tx_data                    (tx_data                  ),
	.tx_data_valid              (tx_data_valid            ),
	.tx_data_ready              (tx_data_ready            ),
	.tx_pin                     (uart_tx                  )
);


endmodule
