//extern int firAsm(chanend c, int H[],int X[], unsigned size);

#define NWORDS 7
 //   .cc_top biquadAsm, biquadAsm.func
    
    .globl fir_ddAsm
    .globl fir_ddAsm.nstackwords
    .linkset fir_ddAsm.nstackwords,NWORDS

#define in		r0
#define H		r1
#define X		r2
#define size	r3
#define x		r4
#define h	 	r5
#define Xoff	r6
#define i 		r7
#define state 	r8
#define Xm  	r9
#define ynl 	r10
#define ynh 	r11

fir_ddAsm:
    entsp NWORDS
    stw   r4, sp[0]
    stw   r5, sp[1]
    stw   r6, sp[2]
    stw   r7, sp[3] // change to make sure that commit goes through to github
    stw   r8, sp[4]
	ldc state,0
    stw   r9, sp[5]
	ldaw Xm,X[size]
    stw   r10, sp[6]



add i,size,0  //reset i to sizeof vector
stw in,X[state] // store word in X[state]
add r10,state,size
stw in,X[r10]   // store word in X[state+size]
bf state,update  //if state==0{state+=size}
updateR:
sub state,state,1

XoffupdateR:
ldc ynl,0 //reset MAC
ldc ynh,0 //reset MAC
bu entrypoint

update:
add state,state,size
ldaw Xoff,Xm[-1];
bu updateR

.align 4
subloop:
maccs ynh,ynl,h,x
entrypoint:
ldw x,Xoff[i] //Xoffset = X-1*int32
sub i,i,1
ldw h,H[i]
bt i,subloop
maccs ynh,ynl,h,x
shl ynh,ynh,1
ldc r4,31
shr ynl,ynl,r4
or  r0,ynh,ynl

ldaw Xoff,Xoff[-1];

allDone:                          // Now just restore all registers.
    ldw   r4, sp[0]
    ldw   r5, sp[1]
    ldw   r6, sp[2]
    ldw   r7, sp[3]
    ldw   r8, sp[4]
    ldw   r9, sp[5]
    ldw   r10, sp[6]
    retsp NWORDS

//    .cc_bottom fir_ddAsm.func
