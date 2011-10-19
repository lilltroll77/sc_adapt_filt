#include <platform.h>
#include <xs1.h>
#include <xclib.h>
#include <print.h>

#define CLOCKDIV 50
static port TXD = PORT_UART_TXD;
static clock clk = XS1_CLKBLK_1;


void txByte(int data[], unsigned size) {
	char byte;
	int int32[1];
	#pragma unsafe arrays
    	for (unsigned i = 0; i < size; i++) {
    	int32[0]=byterev(data[i]);
#pragma loop unroll
    	for(unsigned j=0;j<4;j++){
    	TXD	<: 0; //start bit
		byte=(int32,char[])[j];
#pragma loop unroll
		for(int k=0;k<8;k++)
		TXD <: >> byte;
		TXD<: 1; //stop bit
	}
}}


int fir(int xn, int coeffs[], int state[], int ELEMENTS) {
    unsigned int ynl;
    int ynh;

    ynl = (1<<23);
    ynh = 0;
#pragma unsafe arrays
    for(int j=ELEMENTS-1; j!=0; j--) {
        state[j] = state[j-1];
        {ynh, ynl} = macs(coeffs[j], state[j], ynh, ynl);
    }
    state[0] = xn;
    {ynh, ynl} = macs(coeffs[0], xn, ynh, ynl);
    ynh = ynh << 8 | ynl >> 24;
    return ynh;
}


#pragma unsafe arrays
int lms(int x_ref, int x_des, int mu, int alfa,int coeffs[], int state[],int ELEMENTS) {
#define shift 4;
	unsigned ynl,pnl;
	int ynh,pnh, error,mue;

	for (int j = ELEMENTS - 1 ; j != 0 ; j--) {
				state[j] = state[j - 1];
				{ynh, ynl}=macs(coeffs[j], state[j], 0, 0x80000000);
				{pnh, pnl}=macs(state[j]/ELEMENTS, state[j], alfa, 0);
			}
			state[0] = x_ref<<7;
			{ynh, ynl}=macs(coeffs[0], x_ref<<7, ynh, ynl);
			{pnh, pnl}=macs(state[0], state[0]/ELEMENTS, pnh, pnl);

			ynh = ynh << 1 | ynl >> 31;

			error = x_des-ynh;
			{mue,void}=macs(mu,error,0,0);
			//ldiv
			for(int j = ELEMENTS-1 ; j!=0 ; j--)
				{coeffs[j],void}=macs((state[j]),mue,coeffs[j],0x80000000);
			{coeffs[0],void}=macs((state[0]),mue,coeffs[0],0x80000000);



			// (h,l) is the 64-bit operand
			// a is the 32-bit operand
			// result is in (h,l)
			//{ h, l } = mac(l, a, h*a, 0);
/*
			if(error<0){
			{mue_hi,mue_lo}=mac(mu,-error,0,0);
			sign=neg;
			}else{
			{mue_hi,mue_lo}=mac(mu,error,0,0);
			sign=pos;
			}

			for(int j = ELEMENTS - 1; j>=0 ; j--){
				if(state[j]<0){
				{ynhu,ynl}=mac(mue_lo,(unsigned)(-state[j]),mue_hi*(unsigned)(-state[j]),0);
				signloop=sign^neg; //xor
				}else{
				{ynhu,ynl}=mac(mue_lo,state[j],mue_hi*state[j],0); // == mu*error*x[]
				signloop=sign;
				}muex = ynhu << 8 | ynl >> 24;
				if(sign==neg)
					muex*=-1;

				if (zext(ynhu,23) != ynhu){ //must be place for 8+sign=9 =>32-9=23
					printstr("\n!Warning Overflow in LMS in index ");
				    printint(j);
				    printstr(" at sample ");
				    printint(counter);
				    printstr(", ynh= ");
				    printint(ynhu);
				    printstr(", muex= ");
				    printint(muex);
				}
				if(state[j]>=0 && muex>=0){
					{overflow,state[j]}=mac( 2, muex,0,state[j]);
				if(overflow!=0)
					printstrln("\OVERFLOW IN ADD");
				}
					//elseif(state[j]<0 && muex<0){*/
			return error;
}

int main(){
#define ELEMENTS 256
#define REDUCTION 1
#define POLYNOMIAL 0xEDB88320
#define LEN ELEMENTS*48*REDUCTION

    int errorvec[1+LEN/REDUCTION];
	int state[2][ELEMENTS];
	int hreal[ELEMENTS];
	int hest[ELEMENTS];
	int hi = 0;
	int x_des, x_ref, error,noise;
	unsigned usign1,usign2,seed1,seed2,lo = 0;
	unsigned POW[2] = {0,0};
	int mu=0x10000000;
	int alfa=0;
	timer t;
	t:>usign1;
	t:>seed1;
	if(mu<0){
		printstr("mu must be positive");
		return 0;
}
	// init port logic
	configure_out_port_no_ready(TXD, clk, 1);
	set_clock_div(clk, CLOCKDIV);
	start_clock(clk);
	crc32(usign1, seed1, POLYNOMIAL);

	for (int i = 0; i < ELEMENTS; i++) {
		state[0][i] = 0;
		state[1][i] = 0;
		hest[i]=0;
		crc32(usign1, seed1, POLYNOMIAL);
		hreal[i]= (((int)usign1)>>2);
		{hi,lo}=macs(hreal[i],hreal[i],0,0);
		POW[0] += hi/ELEMENTS;
	}
	t:>usign1;
	printstr("Error power in estimate is: ");
	t:>seed1;
	printuint(POW[0]);
	t:>usign2;
	printstr("\nSending hreal over UART");
	txByte(hreal,ELEMENTS);
	printstr("\nLMS filtering...");
	t:>seed2;
	crc32(usign1, seed1, POLYNOMIAL);// Create random numbers from random seed
	crc32(usign2, seed2, POLYNOMIAL);// Create random numbers from random seed

	for (int j = 0 ; j<LEN ; j++) {
		crc32(usign1, seed1, POLYNOMIAL);
		x_ref=((int) usign1)>>8 ; //23 bits + sign
		crc32(usign2, seed2, POLYNOMIAL);
		noise=((int) usign2)>>16 ;
		x_des=fir(x_ref, hreal, state[0], ELEMENTS);
		errorvec[j/REDUCTION]=lms(x_ref, x_des+noise, mu,alfa, hest, state[1], ELEMENTS);
	}
	errorvec[LEN/REDUCTION]=mu;
	printstr("\nError power after ");
	printint(LEN);
	printstr(" samples is: ");
	for (int i = 0; i < ELEMENTS; i++) {
	 error=hreal[i]-hest[i];
		{hi,lo}=macs(error,error,0,0);
	POW[1] += hi/ELEMENTS;
		}
	printint(POW[1]);
	printstr("\nReduction is: ");
	if(POW[1]>0)
	printint(POW[0]/POW[1]);
	else
	printstr("inf");
	printstrln(" times");
	printstrln("Sending hest over UART");
	txByte(hest,ELEMENTS);
	printstrln("Sending error over UART");
	txByte(errorvec,1+LEN/REDUCTION);




return 0;
}
