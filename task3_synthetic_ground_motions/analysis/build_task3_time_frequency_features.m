function [X,names]=build_task3_time_frequency_features(Task3,cfg)
%BUILD_TASK3_TIME_FREQUENCY_FEATURES Nonstationary ground-motion descriptors.
% Log spectral energy is pooled jointly over normalized time and frequency,
% preserving when energy occurs as well as its frequency content.

[Xbase,baseNames,groups]=build_task3_augmented_features(Task3,cfg);
Xbase=Xbase(:,groups.spectral); baseNames=baseNames(groups.spectral);
timeEdges=linspace(0,1,11); frequencyEdges=logspace(log10(.1),log10(25),13);
n=cfg.num_realizations; tf=zeros(n,(numel(timeEdges)-1)*(numel(frequencyEdges)-1));
for i=1:n
    gm=Task3.Inputs.InputsMatrix(i); t=double(gm.time(:)); a=double(gm.accel(:));
    dt=median(diff(t)); fs=1/dt; a=a-mean(a);
    window=min(256,max(32,2^floor(log2(numel(a)/8)))); overlap=floor(.75*window); nfft=max(256,2*window);
    [S,F,T]=spectrogram(a,hamming(window,'periodic'),overlap,nfft,fs);
    P=abs(S).^2; u=T/max(T(end),eps); row=zeros(1,size(tf,2)); q=0;
    for tb=1:numel(timeEdges)-1
        takeT=u>=timeEdges(tb) & (u<timeEdges(tb+1) | (tb==numel(timeEdges)-1 & u<=1));
        for fb=1:numel(frequencyEdges)-1
            q=q+1; takeF=F>=frequencyEdges(fb) & F<frequencyEdges(fb+1);
            block=P(takeF,takeT);
            if isempty(block), row(q)=log10(eps); else, row(q)=log10(mean(block(:))+eps); end
        end
    end
    tf(i,:)=row;
end
names=baseNames;
for tb=1:numel(timeEdges)-1
    for fb=1:numel(frequencyEdges)-1
        names(end+1)=sprintf('TF_t%02d_f%02d',tb,fb); %#ok<AGROW>
    end
end
X=[Xbase tf]; assert(all(isfinite(X(:))));
end
