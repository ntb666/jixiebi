reg[2:0] servo_id;
reg[11:0] pwm_value;
reg[1:0] time_value;

reg [23:0] servo_id_str;
reg [31:0] pwm_value_str;
reg [31:0] time_value_str;

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

initial begin
	servo_id = 3'd000;
	pwm_value = 4'd0500;
	time_value = 4'd1000;
	servo_id_str = int_to_string(servo_id);
	pwm_value_str = int_to_string(pwm_value);
	time_value_str = int_to_string(time_value);

    tx_data_valid = 1'b1;
end

