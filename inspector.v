module inspector( //INSPECTOR GADGET!!!!
input rst_n,
input data,
input clk,
output reg [31:0] total_cnt,
output reg [7:0] skype_cnt,
output reg [7:0] ftp_cnt,
output reg [7:0] https_cnt,
output reg [7:0] telnet_cnt,
output reg [7:0] ssh_cnt,
output reg [7:0] snmp_cnt,
output reg [7:0] smtp_cnt,
output reg [7:0] nntp_cnt,
output reg [7:0] telnet_session,
output reg [7:0] skype_session,
output reg [7:0] ssh_session
);

localparam SKYPE = 16'd23399;
localparam FTP = 16'd20;
localparam HTTPS = 16'd443;
localparam SSH = 16'd22;
localparam TELNET = 16'd'23;
localparam SMTP = 16'd25;
localparam SNMP = 16'd161
localparam NNTP = 16'd563;

//these registers are used globally
reg [255:0] packet;
reg [8:0] packetcount; //<256 done = 0, =256 done = 1, <256 done = 0
reg [15:0] portnum;
reg [7:0] sessionnum;
//theses are used wires
wire newpacket;
wire done;
//these are called modules
detector DET (rst_n, data, clk, done, newpacket);

always @ * begin
portnum = packet[64:79];
sessionnum = packet[136:143];
end

//this is the master reset statement and the counter block
always @ (posedge clk) begin
	if(!rst_n) begin
		skype_cnt <= 0; //given counters reset
		ftp_cnt <= 0;
		https_cnt <= 0;
		ssh_cnt <= 0;
		telnet_cnt <= 0;
		smtp_cnt <= 0;
		snmp_cnt <= 0;
		nntp_cnt <= 0;
		total_cnt <= 0;
		telnet_session <= 0; 
		skype_session <= 0;
		ssh_session <= 0;
		
		packet <= 0; //my registers
		packetcount <= 0;
		portnum <= 0;
		sessionnum <= 0;
	end
	else begin
		if(newpacket) begin
			packetcount <= packetcount + 1;
			if(packetcount < 257) begin
				packet <= {packet[254:0],data};
				done <= 0;
				total_cnt <= total_cnt;
			end
			else if(packetcount == 257) begin
				packet <= packet;
				done <= 1;
				total_cnt <= total_cnt + 1;
			end
			else begin
				packet <= packet;
				done <= 0;
				total_cnt <= total_cnt;
			end
		end
		else begin
			packetcount <= 0;
		end
	end
end

//checks for port num and increments counter
reg skypeset;
reg ftpset;
reg httpsset;
reg telnetset;
reg sshset;
reg snmpset;
reg smtpset;
reg nntpset;
always @ (posedge clk) begin
	if(!rst_n) begin
		skypeset <= 0;
		ftpset <= 0;
		httpsset <= 0;
		telnetset <= 0;
		sshset <= 0;
		snmpset <= 0;
		smtpset <= 0;
		nntpset <= 0;
	end
	else begin
		if(done && portnum == SKYPE)
			skypeset <= 1;
		else if(done && portnum == FTP)
			ftpset <= 1;
		else if(done && portnum == HTTPS)
			httpsset <= 1;
		else if(done && portnum == TELNET)
			telnetset <= 1;
		else if(done && portnum == SSH)
			sshset <= 1;
		else if(done && portnum == SNMP)
			snmpset <= 1;
		else if(done && portnum == SMTP)
			smtpset <= 1;
		else if(done && portnum == NNTP)
			nntpset <= 1;
		else begin
			skypeset <= 0;
			ftpset <= 0;
			https_cnt <= 0;
			telnetset <= 0;
			sshset <= 0;
			snmpset <= 0;
			smtp_cnt <= 0;
			nntpset <= 0;
		end
	end
end

//adders for the counters
always @ (posedge clk) begin
	skype_cnt <= skype_cnt + skypeset;
	ftp_cnt <= ftp_cnt + ftpset;
	https_cnt <= https_cnt + httpsset;
	telnet_cnt <= telnet_cnt + telnetset;
	ssh_cnt <= ssh_cnt + sshset;
	snmp_cnt <= snmp_cnt + snmpset;
	smtp_cnt <= smtp_cnt + smtpset;
	nntp_cnt <= nntp_cnt + nntpset;
end

//checks the session number
reg [7:0] skypeinit;
reg [7:0] telnetinit;
reg [7:0] sshinit;
reg skypeinitset;
reg telnetinitset;
reg sshinitset;
reg skypesesset;
reg telnetsesset;
reg sshsesset;
always @ (posedge clk) begin
	if(!rst_n) begin
		skypeinit <= 0;
		telnetinit <= 0;
		sshinit <= 0;
		skypeinitset <= 0;
		telnetinitset <= 0;
		sshinitset <= 0;
		skypesesset <= 0;
		telnetsesset <= 0;
		sshsesset <= 0;
	end
	else begin
		if(done) begin
			case(portnum) begin
				SKYPE: begin
					if(skypeinitset) begin
						if(sessionnum > skypeinit) begin
							skypesesset <= 1;
							skypeinit <= sessionnum;
						end
						else begin
							skypesesset <= 0;
							skypeinit <= skypeinit;
						end
					end
					else begin
						skypeinit <= sessionnum;
						skypeinitset <= 1;
						skypesesset <= 1;
					end
				end
				TELNET: begin
					if(telnetinitset) begin
						if(sessionnum > telnetinit) begin
							telnetsesset <= 1;
							telnetinit <= sessionnum;
						end
						else begin
							telnetset <= 0;
							telnetinit <= telnetinit;
						end
					end
					else begin
						telnetinit <= sessionnum;
						telnetinitset <= 1;
						telnetsesset <= 1;
					end
				end
				SSH: begin
					if(sshinitset) begin
						if(sessionnum > sshinit) begin
							sshsesset <= 1;
							sshinit <= sessionnum;
						end
						else begin
							sshsesset <= 0;
							sshinit <= sshinit;
						end
					end
					else begin
						sshinit <= sessionnum;
						sshinitset <= 1;
						sshsesset <= 1;
					end
				end
				default: begin
					skypeinit <= skypeinit;
					telnetinit <= telnetinit;
					sshinit <= sshinit;
					skypeinitset <= skypeinitset;
					telnetinitset <= telnetinitset;
					sshinitset <= sshinitset;
					skypesesset <= 0;
					telnetsesset <= 0;
					sshsesset <= 0;
				end
			endcase	
		end
		else begin
			skypeinit <= skypeinit;
			telnetinit <= telnetinit;
			sshinit <= sshinit;
			skypeinitset <= skypeinitset;
			telnetinitset <= telnetinitset;
			sshinitset <= sshinitset;
			skypesesset <= 0;
			telnetsesset <= 0;
			sshsesset <= 0;
		end
	end
end

always @ (posedge clk) begin //more adders for counters
	skype_session <= skype_session + skypesesset;
	telnet_session <= telnet_session + telnetsesset;
	ssh_session <= ssh_session + sshsesset;
end

endmodule


//==============================================================================================================================================================================================================================================//

module detector( //detects the hex sequence A5A5A5A5
	input rst_n,
	input data,
	input clk,
	input done,
	output reg newpacket
);

reg [31:0] detect;
reg notbusy;

assign notbusy = ~newpacket; // notbusy is always the opposite of newpacket signal. Therefore when there is no new packet

always @ (posedge clk) begin
	if(!rst_n) begin
		newpacket <= 0;
		detect <= 0;
	end	
	else begin
		if(done && newpacket) //this signal is tied to the counter
			newpacket <= 0;
		else begin
			if(notbusy) begin
				newpacket <= (detect & 32h'A5A5A5A5);
			end
			else newpacket <= newpacket; //when newpacket is 1 the counter for reading in the packet should reset.
		end
	end
end

always @ (posedge clk) begin
	detect <= {detect[30:0],data};
end
endmodule