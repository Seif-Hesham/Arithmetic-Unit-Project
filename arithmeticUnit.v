module arithmeticUnit (SW, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR, KEY);
	input [9:0] SW;
	input [3:0] KEY;
	output reg [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output reg [9:0] LEDR;
	reg Clk;
	wire [1:0] in, operator;
	wire sign;
	assign in = SW[1:0];
	assign sign = SW[2];
	assign operator = SW[5:4];
	//assign Reset = KEY[3];
	reg [8:0]intermediate_output;
	reg[7:0] divide_check;
	// reg output_sign;
	reg [1:0]curr_input, curr_op; // 00 +,01 -, 10 *, 11 /
	reg curr_sign;
	wire cout;
	reg [11:0] bcd;
	
	function [1:0] FullAdder;
    input a, b, cin;
    begin
		FullAdder[0] = a ^ b ^ cin;
		FullAdder[1] = (a & b) | (cin & (a ^ b));
		end
	endfunction
	
	function [7:0] Add;
		input [7:0] in1, in2;
		input cin;
		integer i;
		reg carry;
		reg [7:0] sum;
		begin
			carry = cin;
			for (i = 0; i < 8; i = i + 1) begin
            {carry, sum[i]} = FullAdder(in1[i], in2[i], carry);
        	end
		  Add = sum;
		end
	endfunction


	function [1:0] FullSubtractor;
    input a, b, bin;
    begin
        FullSubtractor[0] = a ^ b ^ bin; // Difference
        FullSubtractor[1] = (~a & (b | bin)) | (b & bin); // Borrow
    end
	endfunction
	
	function [7:0] Subtract;
    input [7:0] in1, in2;
    input bin;
    integer i;
    reg borrow;
    reg [7:0] difference;
    begin
        borrow = bin;
        for (i = 0; i < 8; i = i + 1) begin
            {borrow, difference[i]} = FullSubtractor(in1[i], in2[i], borrow);
        end
        Subtract = difference;
    end
	endfunction

	function [8:0] AddWithSigns;
		input [8:0]	in1, in2;
		input cin;
		reg [8:0] sum;
		
		if ((in1[8] && in2[8]) || (!in1[8] && !in2[8])) begin
			sum[7:0] = Add(in1[7:0], in2[7:0], cin);
			sum[8] = in1[8];
		end else if (intermediate_output[7:0] > curr_input) begin // in1, in2
			sum[7:0] = Subtract(in1[7:0], in2[7:0], 1'b0);
			sum[8] = in1[8];
		end else begin
			sum[8:0] = {~in1[8] ,Subtract(in2[7:0], in1[7:0],1'b0)};
		end
		AddWithSigns = sum;
	endfunction

	function [8:0] SubtractWithSigns;
		input [8:0]	in1, in2;
		input bin;
		reg [8:0] diff;
		
		if ((in1[8] && !in2[8]) || (!in1[8] && in2[8])) begin
			diff[7:0] = Add(in1[7:0], in2[7:0], 1'b0);
			diff[8] = in1[8];
		end else begin
			if (in1[7:0] > in2[7:0]) begin
				diff[7:0] = Subtract(in1[7:0], in2[7:0], 1'b0);
				diff[8] = in1[8];
			end else begin
				diff = {~in1[8] ,Subtract(in2[7:0], in1[7:0], 1'b0)};
			end
		end
		SubtractWithSigns = diff;
	endfunction

	function [2:0] Subtract3;
    input [2:0] in1, in2;
    input bin;
    integer i;
    reg borrow;
    reg [2:0] difference;
    begin
        borrow = bin;
        for (i = 0; i < 3; i = i + 1) begin
            {borrow, difference[i]} = FullSubtractor(in1[i], in2[i], borrow);
        end
        Subtract3 = difference;
    end
	endfunction

	function [7:0] Multiply;
		input [7:0] in1;
		input [7:0] in2;
		reg [7:0] add1, add2, add3, add4, add5, add6, add7, add8, out1, out2, out3, out4, out5, out6;
		begin
			add1 = {in2[0] & in1[7], in2[0] & in1[6], in2[0] & in1[5], in2[0] & in1[4], in2[0] & in1[3], in2[0] & in1[2], in2[0] & in1[1], in2[0] & in1[0]};
			add2 = {in2[1] & in1[6], in2[1] & in1[5], in2[1] & in1[4], in2[1] & in1[3], in2[1] & in1[2], in2[1] & in1[1], in2[1] & in1[0], 1'b0};
			add3 = {in2[2] & in1[5], in2[2] & in1[4], in2[2] & in1[3], in2[2] & in1[2], in2[2] & in1[1], in2[2] & in1[0], 2'b00};
			add4 = {in2[3] & in1[4], in2[3] & in1[3], in2[3] & in1[2], in2[3] & in1[1], in2[3] & in1[0], 3'b000};
			add5 = {in2[4] & in1[3], in2[4] & in1[2], in2[4] & in1[1], in2[4] & in1[0], 4'b0000};
			add6 = {in2[5] & in1[2], in2[5] & in1[1], in2[5] & in1[0], 5'b00000};
			add7 = {in2[6] & in1[1], in2[6] & in1[0], 6'b000000};
			add8 = {in2[7] & in1[0], 7'b0000000};
			out1 = Add(add1, add2, 1'b0);
			out2 = Add(out1, add3, 1'b0);
			out3 = Add(out2, add4, 1'b0);
			out4 = Add(out3, add5, 1'b0);
			out5 = Add(out4, add6, 1'b0);
			out6 = Add(out5, add7, 1'b0);
			Multiply = Add(out6, add8, 1'b0);
		end
	endfunction

	function [7:0] Divide;
		input [7:0] dividend;
		input [7:0] divisor;
		reg [7:0] divided;
		reg [7:0] quotient;
		reg append_out;
		integer i, j;
		begin
			quotient = 8'b00000000;
			divided = 8'b00000000;
			//append_out = 0;
			if (divisor == 8'b00000000) begin
				quotient = 8'b11111111;
			end else begin
				for (i = 7; i >= 0; i = i - 1) begin
                divided = {divided[6:0], dividend[i]};
                if (divided >=divisor) begin
                    quotient = {quotient[6:0], 1'b1};
                    divided = Subtract(divided, divisor, 1'b0);
                end else begin
                    quotient = {quotient[6:0], 1'b0};
                end
            end
			end
			Divide = quotient;
		end
	endfunction

	function [11:0] Shift_Add_3;
		 input [7:0] in; // 8-bit binary input
		 reg [11:0] temp_out; // Temporary 12-bit output
		 reg [7:0] shift;     // Temporary shift register
		 reg [3:0] units_out, tens_out, hundreds_out;
		 reg cunit, cten, chun;
		 integer i;

		 begin
			  temp_out = 12'b000000000000; // Initialize temp_out
			  shift = in;                  // Assign input to shift register

			  for (i = 0; i < 7; i = i + 1) begin
					// Shift left and append MSB of shift to temp_out
					temp_out = {temp_out[10:0], shift[7]};
					shift = {shift[6:0], 1'b0}; // Shift input register left

					// Check for correction in units place
					if (temp_out[3] || (temp_out[2] && (temp_out[1] || temp_out[0]))) begin
						 {cunit, units_out} = Add(temp_out[3:0], 4'b0011, 1'b0); // Add 3 to units
						 temp_out[3:0] = units_out;
					end

					// Check for correction in tens place
					if (temp_out[7] || (temp_out[6] && (temp_out[5] || temp_out[4]))) begin
						 {cten, tens_out} = Add(temp_out[7:4], 4'b0011, 1'b0); // Add 3 to tens
						 temp_out[7:4] = tens_out;
					end

					// Check for correction in hundreds place
					if (temp_out[11] || (temp_out[10] && (temp_out[9] || temp_out[8]))) begin
						 {chun, hundreds_out} = Add(temp_out[11:8], 4'b0011, 1'b0); // Add 3 to hundreds
						 temp_out[11:8] = hundreds_out;
					end
			  end
				temp_out = {temp_out[10:0], shift[7]};
				shift = {shift[6:0], 1'b0};
			   Shift_Add_3 = temp_out;
		 end
	endfunction

	
	function [6:0] bcd_to_hex;
		  input [3:0] bcd;
		  begin
				case (bcd)
					 4'b0000: bcd_to_hex = 7'b1000000;
					 4'b0001: bcd_to_hex = 7'b1111001;
					 4'b0010: bcd_to_hex = 7'b0100100;
					 4'b0011: bcd_to_hex = 7'b0110000;
					 4'b0100: bcd_to_hex = 7'b0011001;
					 4'b0101: bcd_to_hex = 7'b0010010;
					 4'b0110: bcd_to_hex = 7'b0000010;
					 4'b0111: bcd_to_hex = 7'b0111000;
					 4'b1000: bcd_to_hex = 7'b0000000;
					 4'b1001: bcd_to_hex = 7'b0010000;
					 default: bcd_to_hex = 7'b1111111;
				endcase
		  end
	endfunction
	reg [7:0] step, operations;
	reg [8:0] intermediate_output1, intermediate_output2;
	reg [3:0] intermediate_output1_start_idx, intermediate_output1_end_idx, intermediate_output2_start_idx, intermediate_output2_end_idx;
	reg start, err;
	reg [39:0] inputs;
	reg [4:0] input_signs;
	integer iterator;
	initial begin
		inputs = 40'b0000000000000000000000000000000000000000;
		operations = 8'b00000000;
		input_signs = 5'b00000;
		step = 8'b00000001;
		start = 0;
		err = 0;
		intermediate_output = 9'b100000000;
		HEX0 = bcd_to_hex(4'b0000);
		HEX1 = bcd_to_hex(4'b1111);
		HEX2 = bcd_to_hex(4'b1111);
		HEX3 = bcd_to_hex(4'b0000);
		HEX4 = bcd_to_hex(4'b0000);
		HEX5 = bcd_to_hex(4'b0000);
	end
	always@(posedge KEY[0]) begin
		if ((step[0] && step[2]) || err) begin
			inputs = 40'b0000000000000000000000000000000000000000;
			operations = 8'b00000000;
			input_signs = 5'b00000;
			start = 0;
			err = 0;
			step = 8'b00000001;
			intermediate_output = 9'b10000000;
			HEX0 = bcd_to_hex(4'b0000);
			HEX1 = bcd_to_hex(4'b1111);
			HEX2 = bcd_to_hex(4'b1111);
			HEX3 = bcd_to_hex(4'b0000);
			HEX4 = bcd_to_hex(4'b0000);
			HEX5 = bcd_to_hex(4'b0000);
			LEDR[0] = 0;
			LEDR[1] = 0;
			LEDR[2] = 0;
			//BONUS==================================================================================
			end else if (step[0] && step[2])begin
			intermediate_output1 = 9'b100000000;
			intermediate_output2 = 9'b100000000;
			intermediate_output1_start_idx = 3'b111;
			intermediate_output2_start_idx = 3'b000;
			intermediate_output1_end_idx = 3'b111;
			if (operations[7:6] == 2'b11 || operations[7:6] == 2'b10) begin
				intermediate_output1[8] = ~(input_signs[3] ^ input_signs[4]);
				case (operations[7:6])
					2'b10: intermediate_output1[7:0] = Multiply(inputs[39:32], inputs[31:24]);
					2'b11: intermediate_output1[7:0] = Divide(inputs[39:32], inputs[31:24]);
				endcase
				intermediate_output1_start_idx = 3'b101;
				intermediate_output1_end_idx = 3'b011;
			end
			if (operations[5:4] == 2'b11 || operations[5:4] == 2'b10) begin
				if (intermediate_output1_start_idx == 3'b101) begin
					intermediate_output1[8] = ~(intermediate_output1[8] ^ input_signs[2]);
					case (operations[5:4])
						2'b10: intermediate_output1[7:0] = Multiply(intermediate_output1[7:0], inputs[23:16]);
						2'b11: intermediate_output1[7:0] = Divide(intermediate_output1[7:0], inputs[23:16]);
					endcase
					intermediate_output1_end_idx =3'b010;
				end else begin
					intermediate_output1[8] = ~(input_signs[3] ^ input_signs[2]);
					case (operations[5:4])
						2'b10: intermediate_output1[7:0] = Multiply(inputs[31:24] ,inputs[23:16]);
						2'b11: intermediate_output1[7:0] = Divide(inputs[31:24] ,inputs[23:16]);
					endcase
					intermediate_output1_start_idx = 3'b100;
					intermediate_output1_end_idx = 3'b010;
				end
			end
			if (operations[1:0] == 2'b10 || operations[1:0] == 2'b11) begin
				intermediate_output2[8] =  ~(input_signs[0] ^ input_signs[1]);
				case (operations[1:0])
					2'b10: intermediate_output2[7:0] = Multiply(inputs[15:8], inputs[7:0]);
					2'b11: intermediate_output2[7:0] = Divide(inputs[15:8], inputs[7:0]);
				endcase
				intermediate_output2_start_idx = 3'b010;
				intermediate_output2_end_idx = 3'b000;
			end
			if (operations[3:2] == 2'b10 || operations[3:2] == 2'b11) begin
				if (intermediate_output1_end_idx == 3'b010 && intermediate_output2_start_idx == 3'b010) begin
					intermediate_output1[8] = ~(intermediate_output1[8] ^ intermediate_output2[8]);
					case (operations[3:2])
						2'b10: intermediate_output1[7:0] = Multiply(intermediate_output1[7:0], intermediate_output2[7:0]);
						2'b11: intermediate_output1[7:0] = Divide(intermediate_output1[7:0], intermediate_output2[7:0]);
					endcase
					intermediate_output1_end_idx = intermediate_output2_end_idx;
				end else if (intermediate_output1_end_idx == 3'b010) begin
					intermediate_output1[8] = ~(intermediate_output1[8] ^ input_signs[1]);
					case (operations[3:2])
						2'b10: intermediate_output1[7:0] = Multiply(intermediate_output1[7:0], inputs[15:8]);
						2'b11: intermediate_output1[7:0] = Divide(intermediate_output1[7:0], inputs[15:8]);
					endcase
					intermediate_output1_end_idx = 3'b001;
				end else if (intermediate_output2_start_idx == 3'b010) begin
					intermediate_output2[8] = ~(intermediate_output2[8] ^ input_signs[2]);
					case (operations[3:2])
						2'b10: intermediate_output2[7:0] = Multiply(inputs[23:16], intermediate_output2[7:0]);
						2'b11: intermediate_output2[7:0] = Divide(inputs[23:16], intermediate_output2[7:0]);
					endcase
					intermediate_output2_start_idx = 3'b011;
				end else begin
					intermediate_output2[8] = ~(inputs[23:16] ^ inputs[15:8]);
					case (operations[3:2])
						2'b10: intermediate_output2[7:0] = Multiply(inputs[23:16], inputs[15:8]);
						2'b11: intermediate_output2[7:0] = Divide(inputs[23:16], inputs[15:8]);
					endcase
					intermediate_output2_start_idx = 3'b011;
					intermediate_output2_end_idx = 3'b001;
				end
			end
			if (intermediate_output1_start_idx == 3'b101) begin
				intermediate_output = intermediate_output1;
			end else begin
				intermediate_output = inputs[39:32];
			end
			if (operations[7:6] == 2'b00 || operations[7:6] == 2'b01) begin
				if (intermediate_output1_start_idx == 3'b100) begin
					case (operations[7:6])
						2'b00: intermediate_output = AddWithSigns(intermediate_output, intermediate_output1, 1'b0);
						2'b01: intermediate_output = SubtractWithSigns(intermediate_output, intermediate_output1, 1'b0);
					endcase
				end else begin
					case (operations[7:6])
						2'b00: intermediate_output = AddWithSigns(intermediate_output, {input_signs[3],inputs[31:24]}, 1'b0);
						2'b01: intermediate_output = SubtractWithSigns(intermediate_output, {input_signs[3], inputs[31:24]}, 1'b0);
					endcase
				end
			end
			if (operations[5:4] == 2'b00 || operations[5:4] == 2'b01) begin
				if (intermediate_output2_start_idx == 3'b011) begin
					case (operations[5:4])
						2'b00: intermediate_output = AddWithSigns(intermediate_output, intermediate_output2, 1'b0);
						2'b01: intermediate_output = SubtractWithSigns(intermediate_output, intermediate_output2, 1'b0);
					endcase
				end else begin
					case (operations[5:4])
						2'b00: intermediate_output = AddWithSigns(intermediate_output, {input_signs[2], inputs[23:16]}, 1'b0);
						2'b01: intermediate_output = SubtractWithSigns(intermediate_output, {input_signs[2], inputs[23:16]}, 1'b0);
					endcase
				end
			end
			if (operations[3:2] == 2'b00 || operations[3:2] == 2'b01) begin
				if (intermediate_output2_start_idx == 3'b010) begin
					case (operations[3:2])
						2'b00: intermediate_output = AddWithSigns(intermediate_output, intermediate_output2, 1'b0);
						2'b01: intermediate_output = SubtractWithSigns(intermediate_output, intermediate_output2, 1'b0);
					endcase
				end else begin
					case (operations[3:2])
						2'b00: intermediate_output = AddWithSigns(intermediate_output, {input_signs[1], inputs[15:8]}, 1'b0);
						2'b01: intermediate_output = SubtractWithSigns(intermediate_output, {input_signs[1], inputs[15:8]}, 1'b0);
					endcase
				end
			end
			if (operations[1:0] == 2'b00 || operations[1:0] == 2'b01) begin
				case (operations[1:0])
					2'b00: intermediate_output = AddWithSigns(intermediate_output, {input_signs[0], inputs[7:0]}, 1'b0);
					2'b01: intermediate_output = SubtractWithSigns(intermediate_output, {input_signs[0], inputs[7:0]}, 1'b0);
				endcase
			end
			bcd = Shift_Add_3(intermediate_output[7:0]);
			HEX5 = bcd_to_hex(bcd[11:8]);
			HEX4 = bcd_to_hex(bcd[7:4]);
			HEX3 = bcd_to_hex(bcd[3:0]);
			if (!intermediate_output[7:0]) begin
				intermediate_output[8] = 1;
				LEDR[2] = 1;
			end else begin
				LEDR[2] = 0;
			end
			LEDR[1] = ~intermediate_output[8];
			if (err) begin
				HEX5 = 7'b0000110;
				HEX4 = 7'b1110111;
				HEX3 = 7'b1110111;
			end
			step = Add(step, 8'b00000001, 1'b0);
			//==========================================================================================================
		end else if (!start) begin // if start, set the output as the input, also set the sign bit
			curr_sign = sign;
			curr_input = in;
			intermediate_output = {curr_sign, 6'b000000, curr_input};
			input_signs = {input_signs[3:0], curr_sign};
			inputs = {inputs[39:8], {6'b000000,curr_input}};
			LEDR[1] = ~curr_sign;
			HEX0 = bcd_to_hex({2'b00, curr_input});
			HEX3 = bcd_to_hex({2'b00, curr_input});
			if (!curr_sign) begin
				HEX1 = 7'b0111111;
			end else begin
				HEX1 = 7'b1111111;
			end
			start = 1;
		end else begin
			step = Add(step, 8'b00000001, 1'b0);
			curr_op = operator;
			curr_input = in;
			curr_sign = sign;
			input_signs = {input_signs[3:0], curr_sign};
			inputs = {inputs[39:8], {6'b000000,curr_input}};
			operations = {operations[5:0], curr_op};
			if (!curr_sign) begin
				HEX1 = 7'b0111111;
			end else begin
				HEX1 = 7'b1111111;
			end
			HEX0 = bcd_to_hex(curr_input);
			if (curr_op == 2'b00) begin // Addition
				intermediate_output = AddWithSigns(intermediate_output, {curr_sign, 6'b000000, curr_input}, 1'b0);
			end else if (curr_op == 2'b01) begin // Subtraction
				intermediate_output = SubtractWithSigns(intermediate_output, {curr_sign, 6'b000000, curr_input}, 1'b0);
			end else if (curr_op == 2'b10) begin
				intermediate_output[8] = ~(intermediate_output[8] ^ curr_sign);
				intermediate_output[7:0] = Multiply(intermediate_output[7:0], {6'b000000, curr_input});
			end else if (curr_op == 2'b11) begin
				intermediate_output[8] = ~(intermediate_output[8] ^ curr_sign);
				divide_check = Divide(intermediate_output[7:0], {6'b000000 ,curr_input});
				intermediate_output[7:0] = divide_check;
				if (divide_check == 8'b11111111) begin
					intermediate_output = 8'b100000000;
					err = 1;
					LEDR[0] = 1;
				end
			end
			bcd = Shift_Add_3(intermediate_output[7:0]);
			HEX5 = bcd_to_hex(bcd[11:8]);
			HEX4 = bcd_to_hex(bcd[7:4]);
			HEX3 = bcd_to_hex(bcd[3:0]);
			if (!intermediate_output[7:0]) begin
				intermediate_output[8] = 1;
				LEDR[2] = 1;
			end else begin
				LEDR[2] = 0;
			end
			LEDR[1] = ~intermediate_output[8];
			if (err) begin
				HEX5 = 7'b0000110;
				HEX4 = 7'b0101111;
				HEX3 = 7'b0101111;
			end
		end
	end
endmodule