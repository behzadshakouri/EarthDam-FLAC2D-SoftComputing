% Adapted from Youngmin Ha's BSD-licensed fmrvr.m (21 January 2015).
% This version accepts an arbitrary candidate-basis count and evaluates the
% same projection terms from sufficient statistics, avoiding the original
% N-by-N Phi*Sigma*Phi' matrix for long time-resolved databases.
function [used,alpha,Mu,invSigma,Omega,nIters]=fmrvr_task3_sufficient(Phi,T,maxIters,tolerance)
N=size(T,1); V=size(T,2); M=size(Phi,2);
assert(size(Phi,1)==N && all(isfinite(Phi),'all') && all(isfinite(T),'all'));
G=Phi'*Phi; G=(G+G')/2; C=Phi'*T; TT=T'*T;
diagG=diag(G); alpha=inf(M,1); mask=false(M,1);
Omega=.1*cov(T,1); Omega=stabilize(Omega,V);
Mu=zeros(0,V); invSigma=zeros(0,0); isConverged=false;

for iterNum=1:maxIters
    if any(mask)
        activeBefore=find(mask); invSigma=G(activeBefore,activeBefore)+diag(alpha(activeBefore));
        MuBefore=invSigma\C(activeBefore,:);
        B=G(activeBefore,:); solved=invSigma\B;
        sPrime=diagG-sum(B.*solved,1)';
        qPrime=C-B'*MuBefore;
    else
        activeBefore=[]; MuBefore=zeros(0,V);
        sPrime=diagG; qPrime=C;
    end
    s=zeros(M,1); q=zeros(M,V);
    for i=1:M
        if mask(i)
            temp=alpha(i)/max(alpha(i)-sPrime(i),eps);
            s(i)=temp*sPrime(i); q(i,:)=temp*qPrime(i,:);
        else
            s(i)=sPrime(i); q(i,:)=qPrime(i,:);
        end
    end

    invOmega=pinv(Omega); deltaL=nan(M,1); task=repmat("non",M,1);
    theta=zeros(M,1); alphaNew=nan(M,1);
    for i=1:M
        theta(i)=real(trace(invOmega*(q(i,:)'*q(i,:))))/V-s(i);
        qPrimeSq=real(trace(invOmega*(qPrime(i,:)'*qPrime(i,:))));
        if theta(i)>0
            if mask(i)
                task(i)="est"; alphaNew(i)=s(i)^2/theta(i);
                if alphaNew(i)>0 && isfinite(alphaNew(i))
                    temp=1/alphaNew(i)-1/alpha(i);
                    denom=sPrime(i)+1/temp; arg=1+sPrime(i)*temp;
                    if denom~=0 && arg>0
                        deltaL(i)=qPrimeSq/denom-V*log(arg);
                    else
                        deltaL(i)=-inf;
                    end
                else
                    deltaL(i)=-inf;
                end
            else
                task(i)="add"; temp=qPrimeSq/max(sPrime(i),eps);
                if temp>0, deltaL(i)=temp-V+V*log(V/temp); else, deltaL(i)=-inf; end
            end
        elseif mask(i)
            task(i)="del"; denom=sPrime(i)-alpha(i); arg=1-sPrime(i)/alpha(i);
            if denom~=0 && arg>0
                deltaL(i)=qPrimeSq/denom-V*log(arg);
            else
                deltaL(i)=-inf;
            end
        end
    end
    finiteChoice=isfinite(deltaL);
    if ~any(finiteChoice), break; end
    choice=deltaL; choice(~finiteChoice)=-inf; [~,i]=max(choice);
    switch task(i)
        case "est"
            changeLogAlpha=log(alpha(i)/alphaNew(i)); alpha(i)=alphaNew(i);
            if abs(changeLogAlpha)<tolerance && all(theta(~mask)<=0), isConverged=true; end
        case "add"
            alpha(i)=s(i)^2/theta(i); mask(i)=true;
        case "del"
            alpha(i)=inf; mask(i)=false;
        otherwise
            break
    end

    % Preserve Ha's update order: Omega uses the model from the beginning
    % of this iteration; the changed alpha set is applied immediately after.
    if iterNum~=1
        if isempty(activeBefore)
            Omega=stabilize(TT/N,V);
        else
            Omega=stabilize((TT-C(activeBefore,:)'*MuBefore)/N,V);
        end
    end
    active=find(mask);
    if isempty(active)
        Mu=zeros(0,V); invSigma=zeros(0,0);
    else
        invSigma=G(active,active)+diag(alpha(active));
        Mu=invSigma\C(active,:);
    end
    if isConverged, break; end
end
nIters=iterNum; used=find(mask);
fprintf('FMRVR iterations=%d, relevance bases=%d/%d.\n',nIters,numel(used),M);
end

function A=stabilize(A,n)
if isscalar(A), A=A*eye(n); end
A=(A+A')/2; scale=max(mean(abs(diag(A))),1e-10);
A=A+eye(n)*(1e-9*scale);
end
