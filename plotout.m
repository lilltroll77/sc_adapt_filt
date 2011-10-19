setup=0;
if(setup)
fclose(s);
s = serial('COM13','BaudRate',1E6);
set(s,'ByteOrder','bigEndian');
set(s,'InputBufferSize',2^16);
fopen(s);
end

ELEMENTS=256;
LEN=ELEMENTS*48;

[B,A]=butter(1,3E-3);
if(s.BytesAvailable>0)
extra=s.BytesAvailable-4*(2*ELEMENTS+LEN+1);
disp(extra);
if(extra>0);
fread(s,extra);
disp(s.BytesAvailable);
elseif(extra<0)
    fread(s,s.BytesAvailable);
    break;
end
href=(2^-31)*fread(s,ELEMENTS,'int32');
hest=(2^-31)*fread(s,ELEMENTS,'int32');
error=(2^-31)*fread(s,LEN,'int32');
stepsize=fread(s,1,'int32');
t=1:ELEMENTS;
figure
subplot(2,1,1)
MAX=max(abs(href-hest));
plot(t,href,t,hest,t,(href-hest)/MAX);
legend('Ref','Est',sprintf('ERROR %.0f dB',-20*log10(MAX)));
grid on;
subplot(2,1,2)
errorflipint=filter(B,A,(error(end:-1:1)).^2);
plot(10*log10(errorflipint(end:-1:ELEMENTS)));
grid on
ylabel('Error level [dB]');
xlabel('Samples');
legend(sprintf('Mu=0x%x',stepsize));
end