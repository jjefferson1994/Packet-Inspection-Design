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