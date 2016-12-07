module processor(clock, reset, button_posedge, bird_y, pipe1_x, pipe1_y, pipe2_x, pipe2_y, pipe3_x, pipe3_y, pipe_y_rand, gameover_flag, game_score, collision_flag, bex_return);

	input clock, reset, button_posedge, collision_flag;
	
	output [31:0] bird_y, pipe1_x, pipe2_x, pipe3_x, game_score;
	output [31:0] pipe1_y, pipe2_y, pipe3_y;
	input [31:0] pipe_y_rand;
	
	output gameover_flag, bex_return;
	
	wire [31:0] gameover_flag_long;
	wire [31:0] collision_flag_long;
	assign collision_flag_long = {31'b0, collision_flag};

	// imem inputs - use this wire for your processor as input to your imem
	wire [31:0] pc;
	
	// dmem inputs - use these wires for your processor as inputs to your dmem
	wire [31:0] dmem_data_in;
	wire [31:0] dmem_address;
	
	
//	output [31:0] debug_data_in;
//	output [11:0] debug_data_address;
	
	// ~~~~~~~~~~~~~~~~~~~~FETCH~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	wire [31:0] pcin;
	wire stall, multdiv_inprogress, dmultordiv;
	register pcreg(clock, ~(multdiv_inprogress | stall | dmultordiv), reset, pcin, pc);
	
	wire [31:0] imemout; 
	// see below for imem instantiation
	
	wire [31:0] FDIRin, FDIRout;
	wire [31:0] fetchstallmuxout;
	wire dobranchjump;
	
	wire [31:0] branchjumppc;
	
	
	wire [31:0] nop;
	assign nop = 32'b0;

	
	wire [31:0] pcplusone;
	
	cla32mult pcincrement(pc, 32'b0, 1'b1, pcplusone);

	mux32bit2to1 pickbranchjumppc(pcplusone, branchjumppc, dobranchjump, pcin);
	
	// F/D pipeline register
	wire [31:0] FDPCin, FDPCout;
	assign FDPCin = pcplusone;
	
	wire didbranchjump;
	dffe branchjumpflush(.d(dobranchjump), .clk(clock), .ena(1'b1), .clrn(~reset), .prn(1'b1), .q(didbranchjump));
	register FDPC(clock, ~(stall | multdiv_inprogress), reset, FDPCin, FDPCout);
	
	wire [31:0] pickflush;
	mux32bit2to1 fetchflush(imemout, nop, didbranchjump, pickflush);
	
	wire [31:0] saveFDIR;
	register saveFDIRstall(clock, 1'b1, reset, imemout, saveFDIR);
	
	wire didstall;
	dffe stallsave(.d(stall), .clk(clock), .ena(1'b1), .clrn(~reset), .prn(1'b1), .q(didstall));
	mux32bit2to1 stallsaveir(pickflush, saveFDIR, didstall, FDIRout);
	
	// ~~~~~~~~~~~~~~~~~~~DECODE~~~~~~~~~~~~~~~~~~~~~~~~~
	
	
	wire [31:0] writeback, DXAin, DXAout, DXBin, DXBout, regAout, regBout;
	wire [4:0] ra, rb, rw;
	wire we;
	regfile registerfile(clock, we, reset, rw, ra, rb, writeback, regAout, regBout, bird_y, pipe1_x, pipe1_y, pipe2_x, pipe2_y, pipe3_x, pipe3_y, pipe_y_rand, gameover_flag_long, game_score, collision_flag_long);
	
	assign gameover_flag = gameover_flag_long[0];
	
	dcontrol dctrl(FDIRout, ra, rb, dmultordiv);
	
	wire [31:0] DXIRin, DXIRout;
	wire [31:0] DXPCin, DXPCout;
	mux32bit2to1 decodeflush(FDIRout, nop, dobranchjump | stall, DXIRin);
	
	// Bypassing for decode stage
	
	wire bypassregA, bypassregB;
	mux32bit2to1 pickbypassregA(regAout, writeback, bypassregA, DXAin);
	mux32bit2to1 pickbypassregB(regBout, writeback, bypassregB, DXBin);
	
	assign DXPCin = FDPCout;
	
	// D/X pipeline register
	register DXPC(clock, ~multdiv_inprogress, reset, DXPCin, DXPCout);
	register DXIR(clock, ~multdiv_inprogress, reset, DXIRin, DXIRout);
	register DXA(clock, ~multdiv_inprogress, reset, DXAin, DXAout);
	register DXB(clock, ~multdiv_inprogress, reset, DXBin, DXBout);
	
	// ~~~~~~~~~~~~~~~~~EXECUTE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	wire itype, bne, blt, j, jr, jal, bex, setx, aluexcept;
	wire [31:0] status;
	wire [4:0] aluop, shamt;
	wire [31:0] N;
	wire [31:0] T;
	
	xcontrol xctrl(DXIRout, itype, aluop, shamt, N, T, bne, blt, j, jr, jal, bex, setx, aluexcept, status);
	
	wire [31:0] pickbypassAout;
	wire [31:0] XMOin, XMOout;
	wire [1:0] bypassA, bypassB;
	
	mux32bit4to1 pickbypassA(DXAout, XMOout, writeback, 32'b0, bypassA, pickbypassAout);
	
	wire [31:0] pickbypassBout;
	mux32bit4to1 pickbypassB(DXBout, XMOout, writeback, 32'b0, bypassB, pickbypassBout);
	
	wire [31:0] pickimmout;
	mux32bit2to1 pickimm(pickbypassBout, N, itype, pickimmout);
	
	wire neq, lt, alu_exception;
	alu alumain(pickbypassAout, pickimmout, aluop, shamt, XMOin, neq, lt, alu_exception, clock, multdiv_inprogress);
		
	assign dobranchjump = (bne & neq) | (blt & lt) | j | jr | jal | bex;
	wire [31:0] pcplusN;
	cla32mult addNtopc(DXPCout, N, 1'b0, pcplusN);
	
	
	// Branch and jumps
	wire [31:0] pickbneout;
	mux32bit2to1 pickbne(DXPCout, pcplusN, neq & bne, pickbneout);
	wire [31:0] pickbltout;
	mux32bit2to1 pickblt(pickbneout, pcplusN, lt & blt, pickbltout);
	wire [31:0] pickjout;
	mux32bit2to1 pickj(pickbltout, T, j, pickjout);
	wire [31:0] pickjalout;
	mux32bit2to1 pickjal(pickjout, T, jal, pickjalout);
	wire [31:0] pickjrout;
	mux32bit2to1 pickjr(pickjalout, pickbypassAout, jr, pickjrout);
	mux32bit2to1 pickbex(pickjrout, T, bex, branchjumppc);
	
	// STATUS stuff
	
	wire [31:0] pickstatusout;

	assign bex_return = bex;
	mux32bit2to1 pickstatus(32'b1, T, setx, pickstatusout);
	register statusreg(clock, setx | alu_exception | button_posedge, reset | ~button_posedge, pickstatusout, status);
	
	
	// X/M pipeline register
	wire [31:0] XMIRin, XMIRout;
	wire [31:0] XMBin, XMBout;
	wire [31:0] XMPCin, XMPCout;
	assign XMIRin = DXIRout;
	assign XMPCin = DXPCout;
	assign XMBin = pickbypassBout;
	register XMPC(clock, ~multdiv_inprogress, reset, XMPCin, XMPCout);
	register XMO(clock, ~multdiv_inprogress, reset, XMOin, XMOout);
	register XMB(clock, ~multdiv_inprogress, reset, XMBin, XMBout);
	register XMIR(clock, ~multdiv_inprogress, reset, XMIRin, XMIRout);
	
	// ~~~~~~~~~~~~~~~~~~~MEMORY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	wire bypassM;
	
	mux32bit2to1 pickbypassM(XMBout, writeback, bypassM, dmem_data_in);
	assign dmem_address = XMOout;
	
	// see DMEM instantiation below
	wire sw;
	mcontrol mctrl(XMIRout, sw);
	
	// M/W pipeline register
	wire [31:0] MWPCin, MWPCout;
	wire [31:0] MWOin, MWOout;
	wire [31:0] MWDin, MWDout;
	wire [31:0] MWIRin, MWIRout;
	assign MWPCin = XMPCout;
	assign MWIRin = XMIRout;
	assign MWOin = XMOout;
	register MWPC(clock, ~multdiv_inprogress, reset, MWPCin, MWPCout);
	register MWO(clock, ~multdiv_inprogress, reset, MWOin, MWOout);
	register MWIR(clock, ~multdiv_inprogress, reset, MWIRin, MWIRout);
	
	
	// ~~~~~~~~~~~~~~WRITEBACK~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	wire lw, jal_inwriteback;
	wire [31:0] pickwritebackOorD;
	wcontrol wctrl(MWIRout, rw, we, lw, jal_inwriteback);
	
	mux32bit2to1 pickwriteback1(MWOout, MWDout, lw, pickwritebackOorD);
	mux32bit2to1 pickwriteback2(pickwritebackOorD, MWPCout, jal_inwriteback, writeback);
	
	// ~~~~~~~~~~~~STALL AND BYPASS CONTROL~~~~~~~~~~~~~~~~~~
	
	bypassstallcontrol bypassstallctrl(FDIRout, DXIRout, XMIRout, MWIRout, bypassA, bypassB, bypassM, bypassregA, bypassregB, stall);
	
//	assign debug_data_in = dmem_data_in;
//	assign debug_data_address = dmem_address[11:0];
	
			
	dmem mydmem(.address(dmem_address[11:0]),
		.clock(clock),
		.data	(dmem_data_in),
		.wren	(sw),
		.q(MWDout)
	);
	
	imem myimem(.address(pc[11:0]),
		.clken(~(stall | multdiv_inprogress | dobranchjump)),
		.clock(clock),
		.q(imemout)
	); 
	
		
endmodule

module bypassstallcontrol(fdir, dxir, xmir, mwir, bypassA, bypassB, bypassM, bypassregA, bypassregB, stall);
	input [31:0] fdir, dxir, xmir, mwir;
	output [1:0] bypassA, bypassB;
	output bypassM, bypassregA, bypassregB, stall;
	wire [4:0] xmir_rd, dxir_rs, dxir_rt, mwir_rd, xmir_opcode, mwir_opcode, dxir_opcode, dxir_rd, fdir_rs, fdir_rt, fdir_rd, fdir_opcode;
	wire xmir_we, mwir_we;
	wire xmir_rtype, xmir_lw, xmir_jal, xmir_addi, xmir_bne, xmir_blt;
	wire mwir_rtype, mwir_lw, mwir_jal, mwir_addi, mwir_bne, mwir_blt;
	wire dxir_rs_equal_xmir_rd, dxir_rs_equal_mwir_rd, dxir_rt_equal_xmir_rd, dxir_rt_equal_mwir_rd, dxir_rd_equal_xmir_rd, dxir_rd_equal_mwir_rd, xmir_rd_equal_mwir_rd, fdir_rs_equal_mwir_rd, fdir_rt_equal_mwir_rd, fdir_rd_equal_mwir_rd;
	wire fdir_rs_equal_dxir_rd, fdir_rt_equal_dxir_rd, fdir_rd_equal_dxir_rd;
	wire dxir_rd_is0, xmir_rd_is0, mwir_rd_is0;
	wire dxir_bne, dxir_blt, fdir_bne, fdir_blt;

	assign fdir_opcode = fdir[31:27];
	assign dxir_opcode = dxir[31:27];
	assign xmir_opcode = xmir[31:27];
	assign mwir_opcode = mwir[31:27];
	assign xmir_rd = xmir[26:22];
	assign mwir_rd = mwir[26:22];
	assign dxir_rs = dxir[21:17];
	assign dxir_rt = dxir[16:12];
	assign dxir_rd = dxir[26:22];
	assign fdir_rs = fdir[21:17];
	assign fdir_rt = fdir[16:12];
	assign fdir_rd = fdir[26:22];
	
	assign dxir_rd_is0 = ~|dxir_rd;
	assign xmir_rd_is0 = ~|xmir_rd;
	assign mwir_rd_is0 = ~|mwir_rd;
	
	assign xmir_rtype = ~|xmir_opcode;
	assign mwir_rtype = ~|mwir_opcode;
	assign xmir_lw = ~xmir_opcode[4] & xmir_opcode[3] & ~xmir_opcode[2] & ~xmir_opcode[1] & ~xmir_opcode[0];
	assign xmir_jal = ~xmir_opcode[4] & ~xmir_opcode[3] & ~xmir_opcode[2] & xmir_opcode[1] & xmir_opcode[0];
	assign xmir_addi = ~xmir_opcode[4] & ~xmir_opcode[3] & xmir_opcode[2] & ~xmir_opcode[1] & xmir_opcode[0];
	assign mwir_lw = ~mwir_opcode[4] & mwir_opcode[3] & ~mwir_opcode[2] & ~mwir_opcode[1] & ~mwir_opcode[0];
	assign mwir_jal = ~mwir_opcode[4] & ~mwir_opcode[3] & ~mwir_opcode[2] & mwir_opcode[1] & mwir_opcode[0];
	assign mwir_addi = ~mwir_opcode[4] & ~mwir_opcode[3] & mwir_opcode[2] & ~mwir_opcode[1] & mwir_opcode[0];
	
	assign dxir_blt = ~dxir_opcode[4] & ~dxir_opcode[3] & dxir_opcode[2] & dxir_opcode[1] & ~dxir_opcode[0];
	assign dxir_bne = ~dxir_opcode[4] & ~dxir_opcode[3] & ~dxir_opcode[2] & dxir_opcode[1] & ~dxir_opcode[0];
	assign dxir_lw = ~dxir_opcode[4] & dxir_opcode[3] & ~dxir_opcode[2] & ~dxir_opcode[1] & ~dxir_opcode[0];
	assign dxir_sw = ~dxir_opcode[4] & ~dxir_opcode[3] & dxir_opcode[2] & dxir_opcode[1] & dxir_opcode[0];
	assign dxir_addi = ~dxir_opcode[4] & ~dxir_opcode[3] & dxir_opcode[2] & ~dxir_opcode[1] & dxir_opcode[0];
	assign dxir_jr = ~dxir_opcode[4] & ~dxir_opcode[3] & dxir_opcode[2] & ~dxir_opcode[1] & ~dxir_opcode[0];
	assign dxir_rtype = ~|dxir_opcode;
	
	assign fdir_blt = ~fdir_opcode[4] & ~fdir_opcode[3] & fdir_opcode[2] & fdir_opcode[1] & ~fdir_opcode[0];
	assign fdir_bne = ~fdir_opcode[4] & ~fdir_opcode[3] & ~fdir_opcode[2] & fdir_opcode[1] & ~fdir_opcode[0];
	assign fdir_lw = ~fdir_opcode[4] & fdir_opcode[3] & ~fdir_opcode[2] & ~fdir_opcode[1] & ~fdir_opcode[0];
	assign fdir_sw = ~fdir_opcode[4] & ~fdir_opcode[3] & fdir_opcode[2] & fdir_opcode[1] & fdir_opcode[0];
	assign fdir_addi = ~fdir_opcode[4] & ~fdir_opcode[3] & fdir_opcode[2] & ~fdir_opcode[1] & fdir_opcode[0];
	assign fdir_jr = ~fdir_opcode[4] & ~fdir_opcode[3] & fdir_opcode[2] & ~fdir_opcode[1] & ~fdir_opcode[0];
	assign fdir_rtype = ~|fdir_opcode;
	
	assign xmir_we = (xmir_rtype | xmir_lw | xmir_jal | xmir_addi) & (|xmir);
	assign mwir_we = (mwir_rtype | mwir_lw | mwir_jal | mwir_addi) & (|mwir);
	
	// for bypass logic
	regselectequal dxir_rs_xmir_rd(dxir_rs, xmir_rd, dxir_rs_equal_xmir_rd);
	regselectequal dxir_rs_mwir_rd(dxir_rs, mwir_rd, dxir_rs_equal_mwir_rd);
	regselectequal dxir_rt_xmir_rd(dxir_rt, xmir_rd, dxir_rt_equal_xmir_rd);
	regselectequal dxir_rt_mwir_rd(dxir_rt, mwir_rd, dxir_rt_equal_mwir_rd);
	regselectequal xmir_rd_mwir_rd(xmir_rd, mwir_rd, xmir_rd_equal_mwir_rd);
	regselectequal dxir_rd_xmir_rd(dxir_rd, xmir_rd, dxir_rd_equal_xmir_rd);
	regselectequal dxir_rd_mwir_rd(dxir_rd, mwir_rd, dxir_rd_equal_mwir_rd);
	regselectequal fdir_rs_mwir_rd(fdir_rs, mwir_rd, fdir_rs_equal_mwir_rd);
	regselectequal fdir_rt_mwir_rd(fdir_rt, mwir_rd, fdir_rt_equal_mwir_rd);
	regselectequal fdir_rd_mwir_rd(fdir_rd, mwir_rd, fdir_rd_equal_mwir_rd);
	
	// for stall logic
	regselectequal fdir_rs_dxir_rd(fdir_rs, dxir_rd, fdir_rs_equal_dxir_rd);
	regselectequal fdir_rt_dxir_rd(fdir_rt, dxir_rd, fdir_rt_equal_dxir_rd);
	regselectequal fdir_rd_dxir_rd(fdir_rd, dxir_rd, fdir_rd_equal_dxir_rd);
	
	wire branchbypassingA[1:0];
	wire regwritebypassingA[1:0];	
	wire branchbypassingB[1:0];
	wire regwritebypassingB[1:0];
	wire lwswbypassingA[1:0];
	wire lwswbypassingB[1:0];
	wire regwritebypassingM;
	wire regwritebypassingregA;
	wire regwritebypassingregB;
	wire branchbypassingregA;
	wire branchbypassingregB;
	wire lwswbypassingregA;
	wire lwswbypassingregB;
	
	wire regwritestall;
	wire branchstall;
	wire lwswstall;
	
	
	// for bypass logic
	assign branchbypassingA[0] = xmir_we & (dxir_bne | dxir_blt | dxir_jr) & dxir_rd_equal_xmir_rd;
	assign branchbypassingA[1] = mwir_we & (dxir_bne | dxir_blt | dxir_jr) & ~dxir_rd_equal_xmir_rd & dxir_rd_equal_mwir_rd;
	assign regwritebypassingA[0] = xmir_we & (dxir_rtype | dxir_addi) & dxir_rs_equal_xmir_rd;
	assign regwritebypassingA[1] = mwir_we & (dxir_rtype | dxir_addi) & ~dxir_rs_equal_xmir_rd & dxir_rs_equal_mwir_rd;
	assign lwswbypassingA[0] = xmir_we & (dxir_lw | dxir_sw) & dxir_rs_equal_xmir_rd;
	assign lwswbypassingA[1] = mwir_we & (dxir_lw | dxir_sw) & ~dxir_rs_equal_xmir_rd & dxir_rs_equal_mwir_rd;

	assign branchbypassingB[0] = xmir_we & (dxir_bne | dxir_blt | dxir_jr) & dxir_rs_equal_xmir_rd;
	assign branchbypassingB[1] = mwir_we & (dxir_bne | dxir_blt | dxir_jr) & ~dxir_rs_equal_xmir_rd & dxir_rs_equal_mwir_rd;
	assign regwritebypassingB[0] = xmir_we & (dxir_rtype | dxir_addi) & dxir_rt_equal_xmir_rd;
	assign regwritebypassingB[1] = mwir_we & (dxir_rtype | dxir_addi) & ~dxir_rt_equal_xmir_rd & dxir_rt_equal_mwir_rd;
	assign lwswbypassingB[0] = xmir_we & (dxir_lw | dxir_sw) & dxir_rd_equal_xmir_rd;
	assign lwswbypassingB[1] = mwir_we & (dxir_lw | dxir_sw) & ~dxir_rd_equal_xmir_rd & dxir_rd_equal_mwir_rd;
	
	assign regwritebypassingM = mwir_we & xmir_rd_equal_mwir_rd; 
	
	assign regwritebypassingregA = mwir_we & (fdir_rtype | fdir_addi) & fdir_rs_equal_mwir_rd;
	assign regwritebypassingregB = mwir_we & (fdir_rtype | fdir_addi) & fdir_rt_equal_mwir_rd;
	assign branchbypassingregA = mwir_we & (fdir_bne | fdir_blt | fdir_jr) & fdir_rd_equal_mwir_rd;
	assign branchbypassingregB = mwir_we & (fdir_bne | fdir_blt | fdir_jr) & fdir_rs_equal_mwir_rd;
	assign lwswbypassingregA = mwir_we & (fdir_lw | fdir_sw) & fdir_rs_equal_mwir_rd;
	assign lwswbypassingregB = mwir_we & (fdir_lw | fdir_sw) & fdir_rd_equal_mwir_rd;
	
	// for stall logic
	assign regwritestall = (fdir_rtype | fdir_addi) & (fdir_rs_equal_dxir_rd | fdir_rt_equal_dxir_rd);
	assign branchstall = (fdir_bne | fdir_blt | fdir_jr) & (fdir_rd_equal_dxir_rd | fdir_rs_equal_dxir_rd);
	assign lwswstall = (fdir_lw | fdir_sw) & (fdir_rs_equal_dxir_rd | fdir_rd_equal_dxir_rd);
	
	
	// for bypass logic
	assign bypassA[0] = (regwritebypassingA[0] | branchbypassingA[0] | lwswbypassingA[0]) & ~xmir_rd_is0;
	assign bypassA[1] = (regwritebypassingA[1] | branchbypassingA[1] | lwswbypassingA[1]) & ~mwir_rd_is0;
	assign bypassB[0] = (regwritebypassingB[0] | branchbypassingB[0] | lwswbypassingB[0]) & ~xmir_rd_is0;
	assign bypassB[1] = (regwritebypassingB[1] | branchbypassingB[1] | lwswbypassingB[1]) & ~mwir_rd_is0;
	assign bypassM = regwritebypassingM & ~mwir_rd_is0;
	assign bypassregA = (regwritebypassingregA | branchbypassingregA | lwswbypassingregA) & ~mwir_rd_is0;
	assign bypassregB = (regwritebypassingregB | branchbypassingregB | lwswbypassingregB) & ~mwir_rd_is0;
	
	// for stall logic
	assign stall = dxir_lw & (regwritestall | branchstall | lwswstall) & ~dxir_rd_is0;
endmodule

module regselectequal(reg1, reg2, isEqual);
	input [4:0] reg1, reg2;
	output isEqual;
	assign isEqual = (reg1[4] ~^ reg2[4]) & (reg1[3] ~^ reg2[3]) &
						  (reg1[2] ~^ reg2[2]) & (reg1[1] ~^ reg2[1]) &
						  (reg1[0] ~^ reg2[0]);
endmodule


module wcontrol(ir, rw, we, lw, jal);
	input [31:0] ir;
	output [4:0] rw;
	output we, lw, jal;
	
	wire [4:0] opcode, rd;
	assign opcode = ir[31:27];
	assign rd = ir[26:22];
	wire rtype, lw_check, jal_check, addi;
	
	assign rtype = ~|opcode;
	assign lw_check = ~opcode[4] & opcode[3] & ~opcode[2] & ~opcode[1] & ~opcode[0];
	assign jal_check = ~opcode[4] & ~opcode[3] & ~opcode[2] & opcode[1] & opcode[0];
	assign addi = ~opcode[4] & ~opcode[3] & opcode[2] & ~opcode[1] & opcode[0];
	
	assign lw = lw_check;
	assign jal = jal_check;
	assign we = (rtype | lw_check | jal_check | addi) & (|ir); // don't activate we on nops
	mux5bit2to1 pickrw(rd, 5'b11111, jal_check, rw);
endmodule

module mcontrol(ir, sw);
	input [31:0] ir;
	output sw;
	wire [4:0] opcode;
	
	assign opcode = ir[31:27];
	assign sw = ~opcode[4] & ~opcode[3] & opcode[2] & opcode[1] & opcode[0];
endmodule

module xcontrol(ir, itype, aluop, shamt, N, T, bne, blt, j, jr, jal, bex, setx, aluexcept, status);
	input [31:0] ir, status;
	input aluexcept;
	output [4:0] aluop, shamt;
	output [31:0] N;
	output [31:0] T;
	output itype, bne, blt, j, jr, jal, bex, setx;
	wire [4:0] opcode;
	wire addi, sw, lw, bne_check, blt_check, rtype;
	
	// Sign extension
	genvar i;
	generate
		for(i = 17; i < 32; i = i + 1) begin: make_N
			assign N[i] = ir[16];
		end
	endgenerate
	assign N[16:0] = ir[16:0];
	
	
	// Zero extension
	genvar k;
	generate
		for(k = 27; k < 32; k = k + 1) begin: make_T
			assign T[k] = 1'b0;
		end
	endgenerate
	assign T[26:0] = ir[26:0];
	
	assign shamt = ir[11:7];
	assign opcode = ir[31:27];
	
	assign bne_check = ~opcode[4] & ~opcode[3] & ~opcode[2] & opcode[1] & ~opcode[0];
	assign blt_check = ~opcode[4] & ~opcode[3] & opcode[2] & opcode[1] & ~opcode[0];
	assign j = ~opcode[4] & ~opcode[3] & ~opcode[2] & ~opcode[1] & opcode[0];
	assign jr = ~opcode[4] & ~opcode[3] & opcode[2] & ~opcode[1] & ~opcode[0];
	assign jal = ~opcode[4] & ~opcode[3] & ~opcode[2] & opcode[1] & opcode[0];
	assign bex_comm = opcode[4] & ~opcode[3] & opcode[2] & opcode[1] & ~opcode[0];
	assign setx = opcode[4] & ~opcode[3] & opcode[2] & ~opcode[1] & opcode[0];
	assign addi = ~opcode[4] & ~opcode[3] & opcode[2] & ~opcode[1] & opcode[0];
	assign sw = ~opcode[4] & ~opcode[3] & opcode[2] & opcode[1] & opcode[0];
	assign lw = ~opcode[4] & opcode[3] & ~opcode[2] & ~opcode[1] & ~opcode[0];
	
	assign bex = bex_comm & (|status);
	
	assign bne = bne_check;
	assign blt = blt_check;
	assign itype = addi | sw | lw;
	assign rtype = ~|opcode;
	
	wire [4:0] pickaluop1;
	mux5bit2to1 pickaluop1mux(5'b00000, 5'b00001, bne_check | blt_check, pickaluop1);
	mux5bit2to1 pickaluop2mux(pickaluop1, ir[6:2], rtype, aluop);
endmodule

module dcontrol(ir, ra, rb, multordiv);
	input [31:0] ir;
	output [4:0] ra, rb;
	output multordiv;
	
	wire [4:0] opcode;
	wire [4:0] aluop;
	wire [4:0] rs, rt, rd;
	wire rtype, sw, lw, addi, mul, div;
	
	assign opcode = ir[31:27];
	assign rd = ir[26:22];
	assign rs = ir[21:17];
	assign rt = ir[16:12];
	assign aluop = ir[6:2];
	
	assign rtype = ~|opcode;
	assign sw = ~opcode[4] & ~opcode[3] & opcode[2] & opcode[1] & opcode[0];
	assign lw = ~opcode[4] & opcode[3] & ~opcode[2] & ~opcode[1] & ~opcode[0];
	assign addi = ~opcode[4] & ~opcode[3] & opcode[2] & ~opcode[1] & opcode[0];
	assign mul = rtype & ~aluop[4] & ~aluop[3] & aluop[2] & aluop[1] & ~aluop[0];
	assign div = rtype & ~aluop[4] & ~aluop[3] & aluop[2] & aluop[1] & aluop[0];
	assign multordiv = mul | div;
	
	mux5bit2to1 pickra(rd, rs, rtype | addi | sw | lw, ra);
	wire [4:0] pickrb1;
	mux5bit2to1 pickrb1mux(rs, rt, rtype | addi, pickrb1);
	mux5bit2to1 pickrbmux(pickrb1, rd, sw, rb);
endmodule

module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, 
					data_result, isNotEqual, isLessThan, alu_exception, clock, multdiv_inprogress);
   input[31:0] data_operandA, data_operandB;
   input[4:0] ctrl_ALUopcode, ctrl_shiftamt;
	input clock;
   output[31:0] data_result;
   output isNotEqual, isLessThan, multdiv_inprogress, alu_exception;
	
	wire overflow, multdiv_exception, multdiv_rdy;
	
	wire sub;
	wire[31:0] neg_data_operandB, addinB, andout, orout, sllout, sraout, addsubout;

	
	assign sub = ~ctrl_ALUopcode[2] & ~ctrl_ALUopcode[1] & ctrl_ALUopcode[0];
	
	inverter32bit i2(data_operandB, neg_data_operandB);
	mux32bit2to1 mux1(data_operandB, neg_data_operandB, sub, addinB);
	
	sll shift1(data_operandA, ctrl_shiftamt, sllout);
	sra shift2(data_operandA, ctrl_shiftamt, sraout);
	
	cla_32bit add1(data_operandA, addinB, sub, addsubout, overflow, andout, orout);
	
	wire opcodemult, opcodediv, multordiv;
	assign opcodemult = ctrl_ALUopcode[2] & ctrl_ALUopcode[1] & ~ctrl_ALUopcode[0];
	assign opcodediv = ctrl_ALUopcode[2] & ctrl_ALUopcode[1] & ctrl_ALUopcode[0];
	assign multordiv = opcodemult | opcodediv;
	
	wire [31:0] multdiv_result;
	wire opinprogress;
	multdiv muldiv1(data_operandA, data_operandB, opcodemult & ~opinprogress, opcodediv & ~opinprogress, clock, multdiv_result, multdiv_exception, multdiv_rdy);
	
	dffe initonce(.d(multdiv_inprogress), .clk(clock), .prn(1'b1), .clrn(~multdiv_rdy), .ena(1'b1), .q(opinprogress));
	dffe progresscheck(.d(multdiv_inprogress), .clk(clock), .prn(~multordiv), .clrn(~multdiv_rdy), .ena(1'b1), .q(multdiv_inprogress));
	
	mux32bit8to1 mux2(addsubout, addsubout, andout, orout, sllout, sraout, multdiv_result, multdiv_result, ctrl_ALUopcode[2:0], data_result);
	
	or o1(isNotEqual, data_result[0], data_result[1], data_result[2], data_result[3], data_result[4], data_result[5], data_result[6], data_result[7], data_result[8], data_result[9], data_result[10], data_result[11], data_result[12], data_result[13], data_result[14], data_result[15], data_result[16], data_result[17], data_result[18], data_result[19], data_result[20], data_result[21], data_result[22], data_result[23], data_result[24], data_result[25], data_result[26], data_result[27], data_result[28], data_result[29], data_result[30], data_result[31]);
	
	assign isLessThan = data_result[31];
	
	assign alu_exception = overflow | multdiv_exception;

endmodule

module multdiv(data_operandA, data_operandB, ctrl_MULT, ctrl_DIV, 
							clock, data_result, data_exception, data_resultRDY);
   input [31:0] data_operandA;
   input [31:0] data_operandB;
   input ctrl_MULT, ctrl_DIV, clock;             
   output [31:0] data_result; 
   output data_exception, data_resultRDY;
	
	wire [31:0] multresult, divresult;
	wire multexcept, divexcept, multrdy, divrdy;
	
	mult m(data_operandA, data_operandB, clock, multresult, multrdy, multexcept, ctrl_MULT); 
	div d(data_operandA, data_operandB, clock, divresult, divrdy, divexcept, ctrl_DIV);
	
	wire multdiv;
	dffe multdivcheck(.d(multdiv), .clk(clock), .clrn(~ctrl_MULT), .prn(~ctrl_DIV), .ena(clock), .q(multdiv));
	
	wire [31:0] result;
	wire except, rdy;
	mux32bit2to1 pickresult(multresult, divresult, multdiv, result);
	mux1bit2to1 pickexcept(multexcept, divexcept, multdiv, except);
	mux1bit2to1 pickrdy(multrdy, divrdy, multdiv, rdy);
	
	//Latch ready, except, and result so they are all ready simultaneously
	dffe readyreg(.d(rdy), .clk(clock), .clrn(1'b1), .prn(1'b1), .ena(1'b1), .q(data_resultRDY));
	dffe exceptreg(.d(except), .clk(clock), .clrn(1'b1), .prn(1'b1), .ena(rdy), .q(data_exception));
	register resultreg(clock, rdy, 1'b0, result, data_result);
endmodule

module div(a, b, clock, result, rdy, except, ctrl);
	input [31:0] a, b;
	input clock, ctrl;
	output [31:0] result;
	output rdy, except;
	
	wire [5:0] count;
	up_counter counter(count, 1'b1, clock, ctrl);
	
	wire dividend_neg;
	dffe dividend_negcheck(.d(a[31]), .clk(clock), .clrn(1'b1), .prn(1'b1), .ena(ctrl), .q(dividend_neg));
	
	wire divisor_neg;
	dffe divisor_negcheck(.d(b[31]), .clk(clock), .clrn(1'b1), .prn(1'b1), .ena(ctrl), .q(divisor_neg));
	
	wire [31:0] nega;
	negator negatea(a, nega);
	
	wire [31:0] picknegaout;
	mux32bit2to1 picknega(a, nega, a[31], picknegaout);
	
	wire [31:0] negb;
	negator negateb(b, negb);
	
	wire [31:0] picknegbout;
	mux32bit2to1 picknegb(b, negb, b[31], picknegbout);
	
	wire [31:0] divisorout;
	register divisor(clock, ctrl, 1'b0, picknegbout, divisorout);
	
	wire [31:0] invertout;
	inverter32bit invertb(divisorout, invertout);
	
	wire [31:0] subout;
	wire [63:0] sllout;
	cla32mult subber(sllout[63:32], invertout, 1'b1, subout);
	
	wire restore;
	assign restore = subout[31];
	wire [31:0] pickrestoreout;
	mux32bit2to1 pickrestore(subout, sllout[63:32], restore, pickrestoreout);
	
	wire [31:0] remhighout;
	register remhigh(clock, clock, ctrl, pickrestoreout, remhighout);
	
	wire [31:0] pickremlowout;
	mux32bit2to1 pickremlow(sllout[31:0], picknegaout, ctrl, pickremlowout);
	
	wire [31:0] remlowout;
	register remlow(clock, clock, 1'b0, pickremlowout, remlowout);

	sll_mult shifter(remhighout, remlowout, sllout);
	
	wire [31:0] quotout;
	wire [31:0] quotin;
	register quotient(clock, clock, ctrl, quotin, quotout);
	assign quotin = {quotout[30:0], ~restore};
	
	wire [31:0] negquotout;
	negator negatequot(quotout, negquotout);
	
	wire diffsigns;
	xor signs(diffsigns, dividend_neg, divisor_neg);
	
	mux32bit2to1 picknegresult(quotout, negquotout, diffsigns, result);

	and checkcount32(rdy, count[5], ~count[4], ~count[3], ~count[2], ~count[1], ~count[0]);

	assign except = ~|divisorout;

endmodule

module mult(a, b, clock, result, rdy, except, ctrl);
	input [31:0] a, b;
	input clock, ctrl;
	output [31:0] result;
	output rdy, except;
	
	wire [5:0] count;
	up_counter counter(count, 1'b1, clock, ctrl);
	
	wire multiplier_neg;
	dffe multiplier_negcheck(.d(b[31]), .clk(clock), .clrn(1'b1), .prn(1'b1), .ena(ctrl), .q(multiplier_neg));
	
	wire [31:0] nega;
	negator negatea(a, nega);
	
	wire [31:0] picknegaout;
	mux32bit2to1 picknega(a, nega, a[31], picknegaout);
	
	wire multiplicand_neg;
	dffe multiplicand_negcheck(.d(a[31]), .clk(clock), .clrn(1'b1), .prn(1'b1), .ena(ctrl), .q(multiplicand_neg));
	
	wire [31:0] multiplicand;
	register multiplicandreg(clock, ctrl, 1'b0, picknegaout, multiplicand);
	
	wire [31:0] addout;
	wire [31:0] prodhighout;
	cla32mult adder(prodhighout, multiplicand, 1'b0, addout);
	
	wire [31:0] prodlowout;
	wire [31:0] pickaddout;
	mux32bit2to1 pickadd(prodhighout, addout, prodlowout[0], pickaddout);
	
	wire [63:0] shiftout;
	sra_mult shiftresult(pickaddout, prodlowout, shiftout);
	
	register producthigh(clock, clock, ctrl, shiftout[63:32], prodhighout);
	
	wire [31:0] negb;
	negator negateb(b, negb);
	
	wire [31:0] picknegbout;
	mux32bit2to1 picknegb(b, negb, b[31], picknegbout);
	
	wire [31:0] pickprodlowout;
	mux32bit2to1 pickprodlow(shiftout[31:0], picknegbout, ctrl, pickprodlowout);
	
	register productlow(clock, clock, 1'b0, pickprodlowout, prodlowout);
	
	wire [31:0] negprodlowout;
	negator negprodlow(prodlowout, negprodlowout);
	
	wire diffsigns;
	xor signs(diffsigns, multiplicand_neg, multiplier_neg);
	
	mux32bit2to1 pickresult(prodlowout, negprodlowout, diffsigns, result);

	assign except = |prodhighout | (prodlowout[31] & |prodlowout[30:0]) | (~diffsigns & prodlowout[31]);

	and checkcount32(rdy, count[5], ~count[4], ~count[3], ~count[2], ~count[1], ~count[0]);
	
	
endmodule



module up_counter(out,enable,clk,reset);
	output [5:0] out;
	input enable, clk, reset;
	reg [5:0] out = 6'd0;
	always @(posedge clk or posedge reset)
		if (reset) begin
		  out <= 6'd0;
		end 
		else if (enable) begin
			// increment out
			case(out)
				6'd0: out <= 6'd1;
				6'd1: out <= 6'd2;
				6'd2: out <= 6'd3;
				6'd3: out <= 6'd4;
				6'd4: out <= 6'd5;
				6'd5: out <= 6'd6;
				6'd6: out <= 6'd7;
				6'd7: out <= 6'd8;
				6'd8: out <= 6'd9;
				6'd9: out <= 6'd10;
				6'd10: out <= 6'd11;
				6'd11: out <= 6'd12;
				6'd12: out <= 6'd13;
				6'd13: out <= 6'd14;
				6'd14: out <= 6'd15;
				6'd15: out <= 6'd16;
				6'd16: out <= 6'd17;
				6'd17: out <= 6'd18;
				6'd18: out <= 6'd19;
				6'd19: out <= 6'd20;
				6'd20: out <= 6'd21;
				6'd21: out <= 6'd22;
				6'd22: out <= 6'd23;
				6'd23: out <= 6'd24;
				6'd24: out <= 6'd25;
				6'd25: out <= 6'd26;
				6'd26: out <= 6'd27;
				6'd27: out <= 6'd28;
				6'd28: out <= 6'd29;
				6'd29: out <= 6'd30;
				6'd30: out <= 6'd31;
				6'd31: out <= 6'd32;
				6'd32: out <= 6'd33;
			endcase
		end
endmodule

module negator(in, out);
	input [31:0] in;
	output [31:0] out;
	
	wire [31:0] inverted;
	inverter32bit invert(in, inverted);
	cla32mult negate(inverted, 32'b0, 1'b1, out);
endmodule

module sra_mult(upper, lower, out);
	input [31:0] upper, lower;
	output [63:0] out;
	wire [63:0] in;
	
	assign in = {upper, lower};
	assign out = {in[63], in[63:1]};
endmodule

module sll_mult(upper, lower, out);
	input [31:0] upper, lower;
	output [63:0] out;
	wire [63:0] in;
	
	assign in = {upper, lower};
	assign out = {in[62:0], 1'b0};
endmodule

module regfile(clock, ctrl_writeEnable, ctrl_reset, ctrl_writeReg, 
ctrl_readRegA, ctrl_readRegB, data_writeReg, data_readRegA, data_readRegB, bird_y, pipe1_x, pipe1_y, pipe2_x, pipe2_y, pipe3_x, pipe3_y, pipe_y_rand, gameover_flag_long, game_score, collision_flag_long);
	input clock, ctrl_writeEnable, ctrl_reset;
   input[4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
   input[31:0] data_writeReg;
   output[31:0] data_readRegA, data_readRegB;
	wire writeEn[0:31];
	wire[31:0] readOut[0:31];
	wire[31:0] readOutA[0:31];
	wire[31:0] readOutB[0:31];
	wire[31:0] ctrl_write_decoded;
	wire[31:0] ctrl_readA_decoded;
	wire[31:0] ctrl_readB_decoded;
	
	input [31:0] collision_flag_long;
	
	output[31:0] bird_y, pipe1_x, pipe2_x, pipe3_x, gameover_flag_long, game_score;
	output [31:0] pipe1_y, pipe2_y, pipe3_y;
	input [31:0] pipe_y_rand;
	
	fiveto32decoder rw(.ctrl(ctrl_writeReg), .onehot(ctrl_write_decoded));
	fiveto32decoder ra(.ctrl(ctrl_readRegA), .onehot(ctrl_readA_decoded));
	fiveto32decoder rb(.ctrl(ctrl_readRegB), .onehot(ctrl_readB_decoded));
	
	wire resets[0:31];
	assign resets[0] = 1'b1; // Hardcoding $r0 = 0
	assign writeEn[0] = 1'b0; // Hardcoding no write enable for register 0
	
	genvar j;
	generate
		for(j = 1; j < 32; j = j + 1) begin: make_resets
			assign resets[j] = ctrl_reset;
			assign writeEn[j] = ctrl_write_decoded[j] & ctrl_writeEnable;
		end
	endgenerate
	
	genvar i;
	generate
		for(i = 0; i < 32; i = i + 1) begin: make_ctrl
			assign data_readRegA = ctrl_readA_decoded[i] ? readOutA[i] : 32'bZ;
			assign data_readRegB = ctrl_readB_decoded[i] ? readOutB[i] : 32'bZ;
			assign readOutA[i] = readOut[i];
			assign readOutB[i] = readOut[i];
			
			if (i == 21)
			begin
			register onereg(.clock(clock), .ctrl_writeEnable(1'b1),
			.ctrl_reset(resets[i]), .writeIn(pipe_y_rand), .readOut(readOut[i]));	
			end
			else if (i == 8)
			begin
			register onereg(.clock(clock), .ctrl_writeEnable(1'b1),
			.ctrl_reset(resets[i]), .writeIn(collision_flag_long), .readOut(readOut[i]));	
			end
			else
			begin
			register onereg(.clock(clock), .ctrl_writeEnable(writeEn[i]),
			.ctrl_reset(resets[i]), .writeIn(data_writeReg), .readOut(readOut[i]));	
			end
		end
	endgenerate
	
	assign bird_y = readOut[1];
	assign pipe1_x = readOut[2];
	assign pipe1_y = readOut[3];
	assign pipe2_x = readOut[4];
	assign pipe2_y = readOut[5];
	assign pipe3_x = readOut[19];
	assign pipe3_y = readOut[20];
	assign gameover_flag_long = readOut[10];
	assign game_score = readOut[11];
endmodule

module register(clock, ctrl_writeEnable, ctrl_reset, writeIn, readOut);
	
	input[31:0] writeIn;
	input clock, ctrl_writeEnable, ctrl_reset;
	output[31:0] readOut;
	
	assign clrn = ~ctrl_reset;

	
	genvar i;
	generate
		for(i = 0; i < 32; i = i + 1) begin: make_dffe			
			dffe dffe_bit(.d(writeIn[i]), .clk(clock), .clrn(clrn), .prn(1'b1), .ena(ctrl_writeEnable), .q(readOut[i]));
		end
	endgenerate	
endmodule

module fiveto32decoder(ctrl, onehot);
	input[4:0] ctrl;
	output[31:0] onehot;
	wire[3:0] enables;
	
	twoto4decoder a(.ctrl(ctrl[4:3]), .onehot(enables));
	threeto8decoder b1(.ctrl(ctrl[2:0]), .onehot(onehot[7:0]), .ena(enables[0]));
	threeto8decoder b2(.ctrl(ctrl[2:0]), .onehot(onehot[15:8]), .ena(enables[1]));
	threeto8decoder b3(.ctrl(ctrl[2:0]), .onehot(onehot[23:16]), .ena(enables[2]));
	threeto8decoder b4(.ctrl(ctrl[2:0]), .onehot(onehot[31:24]), .ena(enables[3]));
endmodule

module threeto8decoder(ctrl, onehot, ena);
	input ena;
	input[2:0] ctrl;
	output[7:0] onehot;
	
	assign onehot[0] = ~ctrl[2] & ~ctrl[1] & ~ctrl[0] & ena;
	assign onehot[1] = ~ctrl[2] & ~ctrl[1] & ctrl[0] & ena;
	assign onehot[2] = ~ctrl[2] & ctrl[1] & ~ctrl[0] & ena;
	assign onehot[3] = ~ctrl[2] & ctrl[1] & ctrl[0] & ena;
	assign onehot[4] = ctrl[2] & ~ctrl[1] & ~ctrl[0] & ena;
	assign onehot[5] = ctrl[2] & ~ctrl[1] & ctrl[0] & ena;
	assign onehot[6] = ctrl[2] & ctrl[1] & ~ctrl[0] & ena;
	assign onehot[7] = ctrl[2] & ctrl[1] & ctrl[0] & ena;
endmodule

module twoto4decoder(ctrl, onehot);
	input[1:0] ctrl;
	output[3:0] onehot;
	
	assign onehot[0] = ~ctrl[1] & ~ctrl[0];
	assign onehot[1] = ~ctrl[1] & ctrl[0];
	assign onehot[2] = ctrl[1] & ~ctrl[0];
	assign onehot[3] = ctrl[1] & ctrl[0];
endmodule

module sll(in, shamt, out);
	input[31:0] in;
	input[4:0] shamt;
	output[31:0] out;
	wire[31:0] out16, out8, out4, out2, out1, mux16, mux8, mux4, mux2;
	
	sll16 s1(in, out16);
	mux32bit2to1 m1(in, out16, shamt[4], mux16);
	
	sll8 s2(mux16, out8);
	mux32bit2to1 m2(mux16, out8, shamt[3], mux8);
	
	sll4 s3(mux8, out4);
	mux32bit2to1 m3(mux8, out4, shamt[2], mux4);
	
	sll2 s4(mux4, out2);
	mux32bit2to1 m4(mux4, out2, shamt[1], mux2);
	
	sll1 s5(mux2, out1);
	mux32bit2to1 m5(mux2, out1, shamt[0], out);
endmodule

module sra(in, shamt, out);
	input[31:0] in;
	input[4:0] shamt;
	output[31:0] out;
	wire[31:0] out16, out8, out4, out2, out1, mux16, mux8, mux4, mux2;
	
	sra16 s1(in, out16);
	mux32bit2to1 m1(in, out16, shamt[4], mux16);
	
	sra8 s2(mux16, out8);
	mux32bit2to1 m2(mux16, out8, shamt[3], mux8);
	
	sra4 s3(mux8, out4);
	mux32bit2to1 m3(mux8, out4, shamt[2], mux4);
	
	sra2 s4(mux4, out2);
	mux32bit2to1 m4(mux4, out2, shamt[1], mux2);
	
	sra1 s5(mux2, out1);
	mux32bit2to1 m5(mux2, out1, shamt[0], out);
endmodule

module sll1(in, out);
	input[31:0] in;
	output[31:0] out;
	
	assign out[0] = 1'b0;
	genvar i;
	generate
		for(i = 1; i < 32; i = i+1) begin: shift
			assign out[i] = in[i-1];
		end
	endgenerate
endmodule

module sra1(in, out);
	input[31:0] in;
	output[31:0] out;
	
	assign out[31] = in[31];
	genvar i;
	generate
		for(i = 0; i < 31; i = i+1) begin: shift
			assign out[i] = in[i+1];
		end
	endgenerate
endmodule

module sll2(in, out);
	input[31:0] in;
	output[31:0] out;
	
	assign out[1:0] = 2'b00;
	genvar i;
	generate
		for(i = 2; i < 32; i = i+1) begin: shift
			assign out[i] = in[i-2];
		end
	endgenerate
endmodule

module sra2(in, out);
	input[31:0] in;
	output[31:0] out;
	
	assign out[31] = in[31];
	assign out[30] = in[31];
	genvar i;
	generate
		for(i = 0; i < 30; i = i+1) begin: shift
			assign out[i] = in[i+2];
		end
	endgenerate
endmodule

module sll4(in, out);
	input[31:0] in;
	output[31:0] out;
	
	assign out[3:0] = 4'b0000;
	genvar i;
	generate
		for(i = 4; i < 32; i = i+1) begin: shift
			assign out[i] = in[i-4];
		end
	endgenerate
endmodule

module sra4(in, out);
	input[31:0] in;
	output[31:0] out;
	
	assign out[31] = in[31];
	assign out[30] = in[31];
	assign out[29] = in[31];
	assign out[28] = in[31];
	genvar i;
	generate
		for(i = 0; i < 28; i = i+1) begin: shift
			assign out[i] = in[i+4];
		end
	endgenerate
endmodule

module sll8(in, out);
	input[31:0] in;
	output[31:0] out;
	
	assign out[7:0] = 8'b00000000;
	genvar i;
	generate
		for(i = 8; i < 32; i = i+1) begin: shift
			assign out[i] = in[i-8];
		end
	endgenerate
endmodule

module sra8(in, out);
	input[31:0] in;
	output[31:0] out;
	
	assign out[31] = in[31];
	assign out[30] = in[31];
	assign out[29] = in[31];
	assign out[28] = in[31];
	assign out[27] = in[31];
	assign out[26] = in[31];
	assign out[25] = in[31];
	assign out[24] = in[31];
	genvar i;
	generate
		for(i = 0; i < 24; i = i+1) begin: shift
			assign out[i] = in[i+8];
		end
	endgenerate
endmodule

module sll16(in, out);
	input[31:0] in;
	output[31:0] out;
	
	assign out[15:0] = 16'b0000000000000000;
	genvar i;
	generate
		for(i = 16; i < 32; i = i+1) begin: shift
			assign out[i] = in[i-16];
		end
	endgenerate
endmodule

module sra16(in, out);
	input[31:0] in;
	output[31:0] out;
	
	assign out[31] = in[31];
	assign out[30] = in[31];
	assign out[29] = in[31];
	assign out[28] = in[31];
	assign out[27] = in[31];
	assign out[26] = in[31];
	assign out[25] = in[31];
	assign out[24] = in[31];
	assign out[23] = in[31];
	assign out[22] = in[31];
	assign out[21] = in[31];
	assign out[20] = in[31];
	assign out[19] = in[31];
	assign out[18] = in[31];
	assign out[17] = in[31];
	assign out[16] = in[31];
	genvar i;
	generate
		for(i = 0; i < 16; i = i+1) begin: shift
			assign out[i] = in[i+16];
		end
	endgenerate
endmodule

module inverter5bit(in, out);
	input[4:0] in;
	output[4:0] out;
	
	genvar i;
	generate
		for(i = 0; i < 5; i = i+1) begin: make_not
			not n1(out[i], in[i]);
		end
	endgenerate	
endmodule

module inverter32bit(in, out);
	input[31:0] in;
	output[31:0] out;
	
	genvar i;
	generate
		for(i = 0; i < 32; i = i+1) begin: make_not
			not n1(out[i], in[i]);
		end
	endgenerate
endmodule

module mux1bit2to1(in0, in1, select, out);
	input in0, in1, select;
	output out;
	wire notsel, choose0, choose1;
	
	not not1(notsel, select);
	and and1(choose0, in0, notsel);
	and and2(choose1, in1, select);
	or or1(out, choose0, choose1);
endmodule

module mux3bit2to1(in0, in1, select, out);
	input[2:0] in0, in1;
	input select;
	output[2:0] out;
	
	genvar i;
	generate
		for(i = 0; i < 3; i = i+1) begin:make_mux
			mux1bit2to1 m1(in0[i], in1[i], select, out[i]);
		end
	endgenerate
endmodule

module mux5bit2to1(in0, in1, select, out);
	input[4:0] in0, in1;
	input select;
	output[4:0] out;
	
	genvar i;
	generate
		for(i = 0; i < 5; i = i+1) begin:make_mux
			mux1bit2to1 m1(in0[i], in1[i], select, out[i]);
		end
	endgenerate
endmodule

module mux32bit2to1(in0, in1, select, out);
	input[31:0] in0, in1;
	input select;
	output[31:0] out;
	
	genvar i;
	generate
		for(i = 0; i < 32; i = i+1) begin:make_mux
			mux1bit2to1 m1(in0[i], in1[i], select, out[i]);
		end
	endgenerate
endmodule

module mux32bit4to1(in0, in1, in2, in3, select, out);
	input [31:0] in0, in1, in2, in3;
	input [1:0] select;
	output [31:0] out;
	wire [31:0] mux0, mux1;
	
	mux32bit2to1 m0(in0, in1, select[0], mux0);
	mux32bit2to1 m1(in2, in3, select[0], mux1);
	
	mux32bit2to1 m3(mux0, mux1, select[1], out);
endmodule

module mux32bit8to1(in0, in1, in2, in3, in4, in5, in6, in7, select, out);
	input[31:0] in0, in1, in2, in3, in4, in5, in6, in7;
	input[2:0] select;
	output[31:0] out;
	wire[31:0] mux0, mux1, mux2, mux3, mux4, mux5;
	
	mux32bit2to1 m0(in0, in1, select[0], mux0);
	mux32bit2to1 m1(in2, in3, select[0], mux1);
	mux32bit2to1 m2(in4, in5, select[0], mux2);
	mux32bit2to1 m3(in6, in7, select[0], mux3);
	
	mux32bit2to1 m4(mux0, mux1, select[1], mux4);
	mux32bit2to1 m5(mux2, mux3, select[1], mux5);
	
	mux32bit2to1 m6(mux4, mux5, select[2], out);
endmodule

module cla32mult(x, y, cin, s);
	input[31:0] x, y;
	input cin;
	output[31:0] s;
	
	wire[31:0] p;
	wire[31:0] g;
	wire[2:0] bigG;
	wire[2:0] bigP;
	wire cla[3:0];
	wire couts[3:0];
	
	genvar i;
	generate
		for (i = 0; i < 32; i = i+1) begin: make_pg
			or o1(p[i], x[i], y[i]);
			and a1(g[i], x[i], y[i]);
		end
	endgenerate
	
	big_g bg1(bigG[0], p[7:0], g[7:0]);
	big_p bp1(bigP[0], p[7:0]);
	big_g bg2(bigG[1], p[15:8], g[15:8]);
	big_p bp2(bigP[1], p[15:8]);
	big_g bg3(bigG[2], p[23:16], g[23:16]);
	big_p bp3(bigP[2], p[23:16]);

	
	assign cla[0] = cin;
	cla1 c1(cla[1], bigG[0], bigP[0], cin);
	cla2 c2(cla[2], bigG[1:0], bigP[1:0], cin);
	cla3 c3(cla[3], bigG[2:0], bigP[2:0], cin);
	wire [3:0] overflows;
	
	cla_8bit m1(x[7:0], y[7:0], cla[0], s[7:0], couts[0], p[7:0], g[7:0], overflows[0]);
	cla_8bit m2(x[15:8], y[15:8], cla[1], s[15:8], couts[1], p[15:8], g[15:8], overflows[1]);
	cla_8bit m3(x[23:16], y[23:16], cla[2], s[23:16], couts[2], p[23:16], g[23:16], overflows[2]);
	cla_8bit m4(x[31:24], y[31:24], cla[3], s[31:24], couts[3], p[31:24], g[31:24], overflows[3]);	

endmodule


module cla_32bit(x, y, cin, s, overflow, andout, orout);
	input[31:0] x, y;
	input cin;
	output[31:0] s;
	output overflow;
	output[31:0] andout;
	output[31:0] orout;
	
	wire[31:0] p;
	wire[31:0] g;
	wire[2:0] bigG;
	wire[2:0] bigP;
	wire cla[3:0];
	wire couts[3:0];
	
	genvar i;
	generate
		for (i = 0; i < 32; i = i+1) begin: make_pg
			or o1(p[i], x[i], y[i]);
			and a1(g[i], x[i], y[i]);
			assign orout[i] = p[i];
			assign andout[i] = g[i];
		end
	endgenerate
	
	big_g bg1(bigG[0], p[7:0], g[7:0]);
	big_p bp1(bigP[0], p[7:0]);
	big_g bg2(bigG[1], p[15:8], g[15:8]);
	big_p bp2(bigP[1], p[15:8]);
	big_g bg3(bigG[2], p[23:16], g[23:16]);
	big_p bp3(bigP[2], p[23:16]);

	
	assign cla[0] = cin;
	cla1 c1(cla[1], bigG[0], bigP[0], cin);
	cla2 c2(cla[2], bigG[1:0], bigP[1:0], cin);
	cla3 c3(cla[3], bigG[2:0], bigP[2:0], cin);
	
	wire [2:0] overflows;
	
	cla_8bit m1(x[7:0], y[7:0], cla[0], s[7:0], couts[0], p[7:0], g[7:0], overflows[0]);
	cla_8bit m2(x[15:8], y[15:8], cla[1], s[15:8], couts[1], p[15:8], g[15:8], overflows[1]);
	cla_8bit m3(x[23:16], y[23:16], cla[2], s[23:16], couts[2], p[23:16], g[23:16], overflows[2]);
	cla_8bit m4(x[31:24], y[31:24], cla[3], s[31:24], couts[3], p[31:24], g[31:24], overflow);	
	
endmodule

module big_g(bigG, p, g);
	input[7:0] p, g;
	output bigG;
	wire w[6:0];
	
	and a1(w[0], p[7], g[6]);
	and a2(w[1], p[7], p[6], g[5]);
	and a3(w[2], p[7], p[6], p[5], g[4]);
	and a4(w[3], p[7], p[6], p[5], p[4], g[3]);
	and a5(w[4], p[7], p[6], p[5], p[4], p[3], g[2]);
	and a6(w[5], p[7], p[6], p[5], p[4], p[3], p[2], g[1]);
	and a7(w[6], p[7], p[6], p[5], p[4], p[3], p[2], p[1], g[0]);
	or o1(bigG, g[7], w[0], w[1], w[2], w[3], w[4], w[5], w[6]);
endmodule

module big_p(bigP, p);
	input[7:0] p;
	output bigP;
	
	and a1(bigP, p[7], p[6], p[5], p[4], p[3], p[2], p[1], p[0]);
endmodule


module cla_8bit(x, y, cin, s, cout, p, g, overflow);
	input[7:0] x, y;
	input cin;
	output[7:0] s;
	output cout, overflow;	
	input[7:0] p;
	input[7:0] g;
	
	wire cla[7:0];
	
	
	assign cla[0] = cin;
	cla1 c1(cla[1], g[0], p[0], cin);
	cla2 c2(cla[2], g[1:0], p[1:0], cin);
	cla3 c3(cla[3], g[2:0], p[2:0], cin);
	cla4 c4(cla[4], g[3:0], p[3:0], cin);
	cla5 c5(cla[5], g[4:0], p[4:0], cin);
	cla6 c6(cla[6], g[5:0], p[5:0], cin);
	cla7 c7(cla[7], g[6:0], p[6:0], cin);
	cla8 c8(cout, g[7:0], p[7:0], cin);
	
	genvar i;
	generate
		for (i = 0; i < 8; i = i+1) begin: make_add
			full_add adder1(.x(x[i]), .y(y[i]), .cin(cla[i]), .s(s[i]));
		end
	endgenerate
	
	xor overflowcheck(overflow, cout, cla[7]);
			
endmodule

module cla1(cla, g, p, cin);
	input g;
	input p;
	input cin;
	output cla;
	wire w;
	
	and a1(w, p, cin);
	or o1(cla, g, w);
endmodule

module cla2(cla, g, p, cin);
	input[1:0] g;
	input[1:0] p;
	input cin;
	output cla;
	wire w[1:0];
	
	and a1(w[0], p[1], g[0]);
	and a2(w[1], p[1], p[0], cin);
	or o1(cla, g[1], w[0], w[1]);
endmodule

module cla3(cla, g, p, cin);
	input[2:0] g;
	input[2:0] p;
	input cin;
	output cla;
	wire w[2:0];
	
	and a1(w[0], p[2], g[1]);
	and a2(w[1], p[2], p[1], g[0]);
	and a3(w[2], p[2], p[1], p[0], cin);
	or o1(cla, g[2], w[0], w[1], w[2]);
endmodule

module cla4(cla, g, p, cin);
	input[3:0] g;
	input[3:0] p;
	input cin;
	output cla;
	wire w[3:0];
	
	and a1(w[0], p[3], g[2]);
	and a2(w[1], p[3], p[2], g[1]);
	and a3(w[2], p[3], p[2], p[1], g[0]);
	and a4(w[3], p[3], p[2], p[1], p[0], cin);
	or o1(cla, g[3], w[0], w[1], w[2], w[3]);
endmodule

module cla5(cla, g, p, cin);
	input[4:0] g;
	input[4:0] p;
	input cin;
	output cla;
	wire w[4:0];
	
	and a1(w[0], p[4], g[3]);
	and a2(w[1], p[4], p[3], g[2]);
	and a3(w[2], p[4], p[3], p[2], g[1]);
	and a4(w[3], p[4], p[3], p[2], p[1], g[0]);
	and a5(w[4], p[4], p[3], p[2], p[1], p[0], cin);
	or o1(cla, g[4], w[0], w[1], w[2], w[3], w[4]);
endmodule

module cla6(cla, g, p, cin);
	input[5:0] g;
	input[5:0] p;
	input cin;
	output cla;
	wire w[5:0];
	
	and a1(w[0], p[5], g[4]);
	and a2(w[1], p[5], p[4], g[3]);
	and a3(w[2], p[5], p[4], p[3], g[2]);
	and a4(w[3], p[5], p[4], p[3], p[2], g[1]);
	and a5(w[4], p[5], p[4], p[3], p[2], p[1], g[0]);
	and a6(w[5], p[5], p[4], p[3], p[2], p[1], p[0], cin);
	or o1(cla, g[5], w[0], w[1], w[2], w[3], w[4], w[5]);
endmodule

module cla7(cla, g, p, cin);
	input[6:0] g;
	input[6:0] p;
	input cin;
	output cla;
	wire w[6:0];
	
	and a1(w[0], p[6], g[5]);
	and a2(w[1], p[6], p[5], g[4]);
	and a3(w[2], p[6], p[5], p[4], g[3]);
	and a4(w[3], p[6], p[5], p[4], p[3], g[2]);
	and a5(w[4], p[6], p[5], p[4], p[3], p[2], g[1]);
	and a6(w[5], p[6], p[5], p[4], p[3], p[2], p[1], g[0]);
	and a7(w[6], p[6], p[5], p[4], p[3], p[2], p[1], p[0], cin);
	or o1(cla, g[6], w[0], w[1], w[2], w[3], w[4], w[5], w[6]);
endmodule

module cla8(cla, g, p, cin);
	input[7:0] g;
	input[7:0] p;
	input cin;
	output cla;
	wire w[7:0];
	
	and a1(w[0], p[7], g[6]);
	and a2(w[1], p[7], p[6], g[5]);
	and a3(w[2], p[7], p[6], p[5], g[4]);
	and a4(w[3], p[7], p[6], p[5], p[4], g[3]);
	and a5(w[4], p[7], p[6], p[5], p[4], p[3], g[2]);
	and a6(w[5], p[7], p[6], p[5], p[4], p[3], p[2], g[1]);
	and a7(w[6], p[7], p[6], p[5], p[4], p[3], p[2], p[1], g[0]);
	and a8(w[7], p[7], p[6], p[5], p[4], p[3], p[2], p[1], p[0], cin);
	or o1(cla, g[7], w[0], w[1], w[2], w[3], w[4], w[5], w[6], w[7]);
endmodule

module full_add(x, y, cin, s);
	input x, y, cin;
	output s;
	xor x1(s, x, y, cin);
endmodule
