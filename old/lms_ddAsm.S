//Sextern void lms_ddAsm(streaming chanend c_ref,streaming chanend c_d, intX[], int H, int SIZE,int u);

#define NWORDS 10
 //   .cc_top lms_ddAsm, lms_ddAsm.func
    
    .globl lms_ddAsm
    .globl lms_ddAsm.nstackwords
    .linkset lms_ddAsm.nstackwords,NWORDS

#define c_ref	r0
#define c_d		r1
#define X		r2
#define H		r3
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
    stw   r4, sp[2]
    stw   r5, sp[3]
    stw   r6, sp[4]
    stw   r7, sp[5] // change to make sure that commit goes through to github
    stw   r8, sp[6]
    stw   r9, sp[7]
    stw   r10, sp[8]
    stw   r11, sp[9]

.align 4
mainloop:

chkct res[c_ref],x
bt x,allDone
in x,res[c_ref]   //read input to x
add i,size,0  //reset i to sizeof vector
stw x,X[state] // store word in X[state]
add r10,state,size
stw x,X[r10]   // store word in X[state+size]
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
or  x,ynh,ynl
in r10,res[c_d]   //read input to x
sub x,r10,x  //e=d-x*h
ldw i,sp[0]
lmsloop:
ldw ynh,Xoff[i]
ldw h,sp[1]  //Change to reg
maccs ynh,ynl,h,x;
shl ynh,ynh,1
stw ynh, Xoff[i]
bt i,lmsloop
maccs ynh,ynl,h,x ;
shl ynh,ynh,1
stw ynh, Xoff[i]


ldaw Xoff,Xoff[-1];
bu mainloop
allDone:                          // Now just restore all registers.

  	inct r3, res[c]
    ldw   r4, sp[0]
    ldw   r5, sp[1]
    ldw   r6, sp[2]
    ldw   r7, sp[3]
    ldw   r8, sp[4]
    ldw   r9, sp[5]
    ldw   r10, sp[6]
    retsp NWORDS

//    .cc_bottom lms_ddAsm.func
