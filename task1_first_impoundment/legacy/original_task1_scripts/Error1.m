function Error=Error1(P,T)
%            Enes GUL enes.gul@inonu.edu.tr
%                   Data Statistical Analysis
%                       24.05.2020, Malatya, Turkey, Inonu University
% 
%                               The best of people is the benefit to
%                               people.(Prophet Muhammed(s.a.v))
%

S=size(P);
if S(1)<S(2)
    P=P';
end

S=size(T);
if S(1)<S(2)
    T=T';
end

diff=P-T;
diff2=diff.^2;
absdiff=abs(diff);
relativeabsdiff=absdiff./abs(T);
diffx=diff./T;
diffx2=diffx.^2;
meant=mean(T);
xpmeant2=(P-meant).^2;
AA=mean(diff2);
BB=mean(xpmeant2);

vaf=(1-(var(diff)/var(T)))*100;

RMSE=sqrt(mean(diff2));
SI=RMSE/mean(T);
MAE=mean(absdiff);
MARE=mean(relativeabsdiff);
RMSRE=mean(diff2./P.^2);
MRE=mean(diffx);
BIAS=mean(diff);
NASH=1-(AA./BB);

SSE=sum((P-T).^2);
n=size(P,1);
StdT=std(T,1);
StdP=std(P,1);
NRMSE=100*RMSE/StdT;%sqrt(SSE/sum((T-mean(T)).^2));
NSC=1-SSE/sum((T-mean(T)).^2);
Cor=sum((P-mean(P)).*(T-mean(T)))/(sqrt(sum((P-mean(P)).^2))*sqrt(sum((T-mean(T)).^2)));
MuT=mean(T);
MuP=mean(P);

%Calculating PERS
P2=T(1:end-1,:);
T2=T(2:end,:);
SSEN=sum((P2-T2).^2);
PERS=1-(SSE/SSEN);
RMSEN=sqrt(SSEN/(n-1));
NRMSEN=100*RMSEN/std(T2,1);

%Passing the output structure
Error.Cor=Cor;
Error.Corkare=Cor^2;
Error.vaf=vaf;
Error.RMSE=RMSE;
Error.SI=SI;
Error.MAE=MAE;
Error.MARE=MARE;
Error.MRE=MRE;
Error.BIAS=BIAS;
Error.Nash=NASH;
Error.NSC=NSC;
Error.RMSRE=RMSRE;
Error.NRMSE=NRMSE;
Error.StdT=StdT;
Error.StdP=StdP;
Error.MuT=MuT;
Error.MuP=MuP;
Error.PERS=PERS;
Error.SSE=SSE;
Error.SSEN=SSEN;  %Sum Squared Error Naive
Error.RMSEN=RMSEN; %RMSE Naive
Error.NRMSEN=NRMSEN; %NRMSE Naive

measpred=T./P;
K=length(measpred);

for j=1:K
if measpred(j,1)<1.1 && measpred(j,1)>0.9 
    
    measpred10(j,1)=measpred(j,1);
   
end
end


ff=find(measpred10>0);
t=length(ff);
Error.a10=t/K;


Error.Er=T-P;
Io=find(Error.Er<=0);
Iu=find(Error.Er>0);
Error.relativediffT2=diffx2;
S1=size(Io,1);
S2=size(Iu,1);

Error.Po=S1/size(Error.Er,1);
Error.Pu=S2/size(Error.Er,1);




