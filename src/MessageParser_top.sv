`timescale 1ns / 1ps

module msg_parser #(
  parameter MAX_MSG_BYTES = 32
)(
  output logic        s_tready,
  input  logic        s_tvalid,
  input  logic        s_tlast,
  input  logic [63:0] s_tdata,
  input  logic [7:0]  s_tkeep,
  output logic        s_terror,					  // Assumed to be an ouput

  output logic                       msg_valid,   // High for one clock to output a message
  output logic [15:0]                msg_length,  // Length of the message
  output logic [8*MAX_MSG_BYTES-1:0] msg_data,    // Data with the LSB on [0]

  input logic clk,
  input logic rst
);

		
	typedef enum {
		IDLE, 
		RECEIVE,
		XXX
	} t_fsm_parser;
        
    t_fsm_parser fsm_parser_r = IDLE;
    t_fsm_parser fsm_parser_n;
    
    logic [15:0] s_msg_num, msg_cnt_n, msg_cnt_r, msg_num_n, msg_num_r, msg_cnt_error_r;
    logic [15:0] s_msg_length, msg_length_n, msg_length_r, msg_length_r2;
    logic [15:0] s_newMsgLength;
    
    logic [15:0] s_tkeep_tmp;
    logic [$clog2(MAX_MSG_BYTES*8)-1:0] trackerMsg_r, trackerMsg_n;
    
    logic [15:0] next_msg_pos_r , next_msg_pos_n, actualMsgPos_r2, actualMsgPos_r, actualMsgPos_n ;
	logic [2:0] relativePos, relativePosInv;
    logic s_tready_int;
    
    logic s_startStream;
    logic msg_valid_r, msg_valid_n;
    logic [2:0] InDataCnt_r, InDataCnt_n, InDataCntPing_r, InDataCntPong_r; 
	
	logic PingNotPong_r, PingNotPong_n;
	logic frameError, frameError_r;
	logic [2:0] SplitWord;

    
    
    // tready is always high for this example
    
    assign s_tready_int = '1;
    assign s_tready     = s_tready_int; 
            
    // MESSAGE PARSER

    assign s_msg_num    = s_tdata[15:0];
    assign s_msg_length = s_tdata[31:16];     
    
    assign s_startStream = s_tvalid && s_tready_int;
	
	/* Relative position of a byte inside a 8 byte long vector*/
	assign relativePos    = next_msg_pos_r[2:0]; 
	assign relativePosInv = ~ relativePos;
	
			                
    // FSM, next state register

    always_ff @(posedge clk, posedge rst)
        if (rst) fsm_parser_r <= IDLE;
        else fsm_parser_r <= fsm_parser_n;    
       
    
    /* FSM, Combinational logic:	
		Two-stage based FSM	which gets triggered when tvalid+tuser
		is received, when being IDLE. The FSM stays receiving until
		tlast arrives. 
	
	*/
    always_comb begin
		// Default
        msg_num_n          <= msg_num_r;
        msg_length_n       <= msg_length_r;  
        trackerMsg_n       <= trackerMsg_r;
        msg_cnt_n          <= msg_cnt_r;
        actualMsgPos_n     <= actualMsgPos_r;   
        next_msg_pos_n     <= next_msg_pos_r; 
        msg_valid_n        <= '0;
        InDataCnt_n        <= InDataCnt_r + 1;     
		PingNotPong_n      <= PingNotPong_r;
        // FSM
        fsm_parser_n       <= XXX; // for debugging         
                              
        case(fsm_parser_r)        
            IDLE: begin
                fsm_parser_n <= IDLE; // @ Default             
                if  (s_startStream) begin                    
                    msg_num_n      <= s_msg_num;        // Number of msgs inside a frame
                    msg_length_n   <= s_msg_length;     // Length of the first message
                    actualMsgPos_n <= 4;                // Position of the payload for the current msg
					trackerMsg_n   <= 4;                // Payload tracker to detect the end of a msg
                    next_msg_pos_n <= s_msg_length + 4; // Calculate the position for the next msg
					PingNotPong_n  <= '1;               // En/disable a MUX to use different alignments 
                    fsm_parser_n   <= RECEIVE; // @ Next State
                end else begin                    
                    msg_num_n          <= '0;
                    msg_length_n       <= '0;
                    trackerMsg_n       <= '0;
                    msg_cnt_n          <= '0;
                    next_msg_pos_n     <= '0;
                    msg_valid_n        <= '0;
                    InDataCnt_n        <= '0;
                    actualMsgPos_n     <= '0;
                end
            end
            RECEIVE: begin
                fsm_parser_n   <= RECEIVE;            // @ Default
				trackerMsg_n   <= trackerMsg_r + 8;	  // Track the payload to detect the end of a msg
				/* In this cycle, part of the next message might be received, including the length field*/
                if (trackerMsg_r + 8 > msg_length_r) begin                 
					/* Anticipate the end of the message, store the new length field,
					save the position of the next message as the current one, calculate
					the end position of the following message */
                    msg_length_n   <= s_newMsgLength;
                    next_msg_pos_n <= next_msg_pos_r + 2 + s_newMsgLength;
                    actualMsgPos_n <= next_msg_pos_r + 2;
                    msg_cnt_n      <= msg_cnt_r + 1;  // Can be used to detect errors 
					InDataCnt_n    <= SplitWord;         // Internal counter to calculate missalingment					
					trackerMsg_n   <= relativePosInv; // Store number of payload bytes present in a new message -type of- input
                    msg_valid_n    <= '1;             // Asserts the output message
					PingNotPong_n  <= ~PingNotPong_r; // Switch to output vector
                    if (s_tlast ) begin               // End of Frame
                        fsm_parser_n   <= IDLE; 
                    end                                                                               
                end
            end
            default: begin                
                msg_num_n          <= 'x;
                msg_length_n       <= 'x;  
                trackerMsg_n       <= 'x;
                msg_cnt_n          <= 'x;
                next_msg_pos_n     <= 'x;
                InDataCnt_n        <= 'x;
                actualMsgPos_n     <= 'x;
				PingNotPong_n      <= 'x;
            end
        endcase
    end    
    
    // FSM Output Registers
    always_ff @(posedge clk)
    begin        
        msg_num_r          <= msg_num_n;
        msg_length_r       <= msg_length_n;  
        trackerMsg_r       <= trackerMsg_n;
        msg_cnt_r          <= msg_cnt_n;
        next_msg_pos_r     <= next_msg_pos_n;
        msg_valid_r        <= msg_valid_n;
        InDataCnt_r        <= InDataCnt_n;
        actualMsgPos_r     <= actualMsgPos_n;
		PingNotPong_r      <= PingNotPong_n;
    end
	
	/* Error alert: an error pulse is generated synchronous to valid
		signal when the size of the frame doesn't match with the
		number of generated messages.
	*/
	
	logic tlast_r, flag_error_r;
	
	always_ff @(posedge clk) 
	begin
	   tlast_r         <= s_tlast;
	   msg_cnt_error_r <= msg_cnt_r;
	   flag_error_r    <= '1; 
	   if (msg_num_r == msg_cnt_r + 1 ) begin
	   	   flag_error_r    <= '0;
	   end
	end
	
	assign frameError = flag_error_r && tlast_r && msg_valid_r; 

	
	/* Two counters control two different Muxes
			Two 320-bit buffers are used to composse the final result
			The difference between the two registers is one is saving the 
			previous message as the second one is saving the current one.  
			A "ping-pong" signal selects which of those is the final output.
			To create the 320-bit vectors, the Ping-Pong counters (InDataCntP[i|o]ng_r)
			control the position of the 64bit input inside the 320 bit vector. 
			Input data is saved from right [0] to left [319], to store the oldest
			data in the LSB, following Little Endianess. There are two different
			scenarios:
				1) The 64bit input has a portion of the previous message and a portion of 
					the new message
				2) The 64bit input has only new data. 
			The "SplitWord" signal reflects this difference, adjusting in which 64 bit slice
			is stored the arriving data.
			
			
			Before that, 16 registers are storing different alignments of the
			final message. 8 registers store the "ping" version, 8 registers
			store the "pong" version. One of these 8 vectors has the correct
			alginment, which is dependant of the position of the first byte
			after the length field. The saved initial position is used to select
			the right alignments (next_msg_pos_r).
	*/
	
	/* Differenciate when there are two messages in the same 64bit input */
	always_comb begin
		case (relativePos[2:0])
			3'd6: SplitWord <= 3'b000;
			3'd7: SplitWord <= 3'b000;
			3'd0: SplitWord <= 3'b000;
			default: SplitWord <= 3'b001;
		endcase
	end
	
	/* Use two counters to select the right postion of the 64 bit chunk among the 320 bit buffer */
	
	assign InDataCntPing_r = PingNotPong_r ? InDataCnt_r : '0;
	assign InDataCntPong_r = PingNotPong_r ? '0 : InDataCnt_r;

        
    /* Discover the length field in a new message */
    // TODO: Could be done with a for/generate loop
	
    always_comb begin
        case (next_msg_pos_r [2:0])
            4'd0: s_newMsgLength = s_tdata[15:0];
            4'd1: s_newMsgLength = s_tdata[23:8]; 
            4'd2: s_newMsgLength = s_tdata[31:16];
            4'd3: s_newMsgLength = s_tdata[39:24];
            4'd4: s_newMsgLength = s_tdata[47:32];
            4'd5: s_newMsgLength = s_tdata[55:40];
            4'd6: s_newMsgLength = s_tdata[63:48];
            4'd7: s_newMsgLength = {8'b0,s_tdata[63:56]};    // message can't be longer than 32 bytes, no need to use MSB             
        endcase
    end     
	
	/* Some signal declarations. Some style guides would advert against 
		declaring signals in the middle of the code. In this case works as a divider */
    
    logic [63:0] InDataPing0, InDataPing1, InDataPing2, InDataPing3, InDataPing4;
	logic [63:0] InDataPong0, InDataPong1, InDataPong2, InDataPong3, InDataPong4;
    logic [319:0] MsgUnalligned, MsgUnallignedPing, MsgUnallignedPong;
    logic [319:0] DataOutOpt0, DataOutOpt1, DataOutOpt2, DataOutOpt3;
    logic [319:0] DataOutOpt4, DataOutOpt5, DataOutOpt6, DataOutOpt7;
    
        
    /* Register 8 differents "shapes" of the incoming message to 
		finally pick the one that is alligned. More timing-friendly than a Barrel Shifter.
        Hence, 8 bytes is the maximum shifting, narrowing the total number of registers
		needed */    
			
    assign MsgUnallignedPing = {InDataPing4, InDataPing3, InDataPing2, InDataPing1, InDataPing0};     
	assign MsgUnallignedPong = {InDataPong4, InDataPong3, InDataPong2, InDataPong1, InDataPong0};     
	
	assign MsgUnalligned = PingNotPong_r ?  MsgUnallignedPing : MsgUnallignedPong;
    
	
	// Ping Mux
    always_comb begin
        case (InDataCntPing_r)
            3'd0: InDataPing0 <= s_tdata;
            3'd1: InDataPing1 <= s_tdata;
            3'd2: InDataPing2 <= s_tdata;
            3'd3: InDataPing3 <= s_tdata;
            3'd4: InDataPing4 <= s_tdata;
            default: begin
                InDataPing0 <= 'x;
                InDataPing1 <= 'x;
                InDataPing2 <= 'x;
                InDataPing3 <= 'x;
                InDataPing4 <= 'x;            
            end
        endcase        
    end
		
	// Pong Mux
	always_comb begin
        case (InDataCntPong_r)
            3'd0: InDataPong0 <= s_tdata;
            3'd1: InDataPong1 <= s_tdata;
            3'd2: InDataPong2 <= s_tdata;
            3'd3: InDataPong3 <= s_tdata;
            3'd4: InDataPong4 <= s_tdata;
            default: begin
                InDataPong0 <= 'x;
                InDataPong1 <= 'x;
                InDataPong2 <= 'x;
                InDataPong3 <= 'x;
                InDataPong4 <= 'x;            
            end
        endcase        
    end
    
    /* One of these has the right alignment (length field removed )*/
    always_ff @(posedge clk) begin
        if (PingNotPong_r) begin
            DataOutOpt0 <= MsgUnallignedPing;
            DataOutOpt1 <= MsgUnallignedPing >> 8;
            DataOutOpt2 <= MsgUnallignedPing >> 16;
            DataOutOpt3 <= MsgUnallignedPing >> 24;
            DataOutOpt4 <= MsgUnallignedPing >> 32;
            DataOutOpt5 <= MsgUnallignedPing >> 40;
            DataOutOpt6 <= MsgUnallignedPing >> 48;
            DataOutOpt7 <= MsgUnallignedPing >> 56;
		end else begin
            DataOutOpt0 <= MsgUnallignedPong;
            DataOutOpt1 <= MsgUnallignedPong >> 8;
            DataOutOpt2 <= MsgUnallignedPong >> 16;
            DataOutOpt3 <= MsgUnallignedPong >> 24;
            DataOutOpt4 <= MsgUnallignedPong >> 32;
            DataOutOpt5 <= MsgUnallignedPong >> 40;
            DataOutOpt6 <= MsgUnallignedPong >> 48;
            DataOutOpt7 <= MsgUnallignedPong >> 56;		
		end
    end
    
    /* Pick the right output depending on the position of the first payload byte inside the 64-bit input data */
    always_comb begin
        case (actualMsgPos_r2[2:0])
            4'd0: msg_data <= DataOutOpt0;
            4'd1: msg_data <= DataOutOpt1;
            4'd2: msg_data <= DataOutOpt2;
            4'd3: msg_data <= DataOutOpt3;
            4'd4: msg_data <= DataOutOpt4;
            4'd5: msg_data <= DataOutOpt5;
            4'd6: msg_data <= DataOutOpt6;
            4'd7: msg_data <= DataOutOpt7;
            default: msg_data <= 'x;
        endcase
    end
        
    /* Synchronize with data output and valid signal. Valid signal 
		is asserted when msg_length_r and actualMsgPos_r are getting 
		updated with new values, thus the previous value needs to be 
		used instead.
	*/
    always_ff @(posedge clk) begin
        msg_length_r2   <= msg_length_r;
        actualMsgPos_r2 <= actualMsgPos_r;
    end    
	
	/* Outputs */
    
    assign msg_valid  = msg_valid_r;
    assign msg_length = msg_length_r2;
	
	assign s_terror   = frameError; // Synchronized with valid signal

endmodule
