// Data written to registers R0 to R5 are sent to the H digits
module seg7_scroll (Data, Addr, Sel, Resetn, Clock, H5, H4, H3, H2, H1, H0);
	input [6:0] Data;
	input [2:0] Addr;
	input Sel, Resetn, Clock;
	output [6:0] H5, H4, H3, H2, H1, H0;
	
	reg E0, E1, E2, E3, E4, E5;
	parameter Add0 = 3'b000, Add1= 3'b001,Add2 = 3'b010,
	          Add3 = 3'b011, Add4= 3'b100,Add5 = 3'b101;
				 
	always @(*)
	begin
		case (Addr)
			Add0: 
				begin
					E0 =1'b1; 
					E1 =1'b0; 
					E2 =1'b0; 
					E3 =1'b0; 
					E4 =1'b0; 
					E5 =1'b0;
				end
			Add1: 
				begin
					E0 =1'b0; 
					E1 =1'b1; 
					E2 =1'b0; 
					E3 =1'b0; 
					E4 =1'b0; 
					E5 =1'b0; 
				end
			Add2: 
				begin
					E0 =1'b0; 
					E1 =1'b0; 
					E2 =1'b1; 
					E3 =1'b0; 
					E4 =1'b0; 
					E5 =1'b0; 
				end
			Add3: 
				begin
					E0 =1'b0; 
					E1 =1'b0; 
					E2 =1'b0; 
					E3 =1'b1; 
					E4 =1'b0; 
					E5 =1'b0; 
				end
			Add4: 
				begin
					E0 =1'b0; 
					E1 =1'b0; 
					E2 =1'b0; 
					E3 =1'b0; 
					E4 =1'b1; 
					E5 =1'b0; 
				end
			Add5: 
				begin
					E0 =1'b0; 
					E1 =1'b0; 
					E2 =1'b0; 
					E3 =1'b0; 
					E4 =1'b0; 
					E5 =1'b1; 
				end
			default:
					E0 =1'b0; 
					E1 =1'b0; 
					E2 =1'b0; 
					E3 =1'b0; 
					E4 =1'b0; 
					E5 =1'b0; 
		endcase
	end	
	

	regne R0(Data, Clock, Resetn, E0 & Sel, H0);
	regne R0(Data, Clock, Resetn, E1 & Sel, H1);
	regne R0(Data, Clock, Resetn, E2 & Sel, H2);
	regne R0(Data, Clock, Resetn, E3 & Sel, H3);
	regne R0(Data, Clock, Resetn, E4 & Sel, H4);
	regne R0(Data, Clock, Resetn, E5 & Sel, H5);
	
endmodule

module regne (R, Clock, Resetn, E, Q);
	parameter n = 7;
	input [n-1:0] R;
	input Clock, Resetn, E;
	output [n-1:0] Q;
	reg [n-1:0] Q;	
	
	always @(posedge Clock)
		if (Resetn == 0)
			Q <= {n{1'b0}};
		else if (E)
			Q <= R;
endmodule
