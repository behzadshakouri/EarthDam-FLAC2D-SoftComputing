clc
clear all %#ok
close all

%------------------Adresses-------------------------------
Samples='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\RVs_Static\Samples\';
Maku_PT1_Models='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Soft Computing\';
QOIs='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Soft Computing\QOIs\';
Results='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Soft Computing\QOIs\Results\';


%------------------Input Matrix Generation-------------------------------

cd(Results);

load results.mat

nsample=[50 100 150 200 300 400 500];

node_row(1,:)=[14173 14198 14223 11469 11494 11519 16877 16902 16927];


Comment1='ELM';
Comment2='ELMABC';
Comment3='ELMACOR';
Comment4='ELMIGWO';

for k=1:numel(nsample)
    i=1;
    while i<=numel(node_row)
        if i==1
    sumation(:,:,i,k)=ELMdata(:,:,i,k); %#ok
        else
    sumation(:,:,i,k)=ELMdata(:,:,i,k)+sumation(:,:,i-1,k); %#ok  
        end
    i=i+1;
    end
    average(:,1,k)=sumation(:,1,numel(node_row),k)/numel(node_row); %#ok
    average(:,2,k)=sumation(:,2,numel(node_row),k)/numel(node_row); %#ok
    average(:,3,k)=sumation(:,3,numel(node_row),k)/numel(node_row); %#ok
    average(:,4,k)=sumation(:,4,numel(node_row),k)/numel(node_row); %#ok
    average(:,5,k)=sumation(:,5,numel(node_row),k)/numel(node_row); %#ok
    average(:,6,k)=sumation(:,6,numel(node_row),k)/numel(node_row); %#ok
    average(:,7,k)=sumation(:,7,numel(node_row),k)/numel(node_row); %#ok
    average(:,8,k)=sumation(:,8,numel(node_row),k)/numel(node_row); %#ok
end

for k=1:numel(nsample)
 filename1 = [Comment1 '_nsample' num2str(nsample(1,k)) '_Average_Statistics' '.xlsx'];
 sheet=1;
 writematrix(average(:,:,k),filename1,'Sheet',sheet,'Range','R1');
end

for k=1:numel(nsample)
    i=1;
    while i<=numel(node_row)
        if i==1
    sumation(:,:,i,k)=ELMABCdata(:,:,i,k);
        else
    sumation(:,:,i,k)=ELMABCdata(:,:,i,k)+sumation(:,:,i-1,k);
        end
    i=i+1;
    end
    average(:,1,k)=sumation(:,1,numel(node_row),k)/numel(node_row); 
    average(:,2,k)=sumation(:,2,numel(node_row),k)/numel(node_row); 
    average(:,3,k)=sumation(:,3,numel(node_row),k)/numel(node_row); 
    average(:,4,k)=sumation(:,4,numel(node_row),k)/numel(node_row); 
    average(:,5,k)=sumation(:,5,numel(node_row),k)/numel(node_row); 
    average(:,6,k)=sumation(:,6,numel(node_row),k)/numel(node_row); 
    average(:,7,k)=sumation(:,7,numel(node_row),k)/numel(node_row); 
    average(:,8,k)=sumation(:,8,numel(node_row),k)/numel(node_row); 
end

for k=1:numel(nsample)
 filename1 = [Comment2 '_nsample' num2str(nsample(1,k)) '_Average_Statistics' '.xlsx'];
 sheet=1;
 writematrix(average(:,:,k),filename1,'Sheet',sheet,'Range','R1');
end

for k=1:numel(nsample)
    i=1;
    while i<=numel(node_row)
        if i==1
    sumation(:,:,i,k)=ELMACORdata(:,:,i,k); 
        else
    sumation(:,:,i,k)=ELMACORdata(:,:,i,k)+sumation(:,:,i-1,k);   
        end
    i=i+1;
    end
    average(:,1,k)=sumation(:,1,numel(node_row),k)/numel(node_row); 
    average(:,2,k)=sumation(:,2,numel(node_row),k)/numel(node_row); 
    average(:,3,k)=sumation(:,3,numel(node_row),k)/numel(node_row); 
    average(:,4,k)=sumation(:,4,numel(node_row),k)/numel(node_row); 
    average(:,5,k)=sumation(:,5,numel(node_row),k)/numel(node_row); 
    average(:,6,k)=sumation(:,6,numel(node_row),k)/numel(node_row); 
    average(:,7,k)=sumation(:,7,numel(node_row),k)/numel(node_row); 
    average(:,8,k)=sumation(:,8,numel(node_row),k)/numel(node_row); 
end

for k=1:numel(nsample)
 filename1 = [Comment3 '_nsample' num2str(nsample(1,k)) '_Average_Statistics' '.xlsx'];
 sheet=1;
 writematrix(average(:,:,k),filename1,'Sheet',sheet,'Range','R1');
end

for k=1:numel(nsample)
    i=1;
    while i<=numel(node_row)
        if i==1
    sumation(:,:,i,k)=ELMIGWOdata(:,:,i,k); 
        else
    sumation(:,:,i,k)=ELMIGWOdata(:,:,i,k)+sumation(:,:,i-1,k);   
        end
    i=i+1;
    end
    average(:,1,k)=sumation(:,1,numel(node_row),k)/numel(node_row); 
    average(:,2,k)=sumation(:,2,numel(node_row),k)/numel(node_row); 
    average(:,3,k)=sumation(:,3,numel(node_row),k)/numel(node_row); 
    average(:,4,k)=sumation(:,4,numel(node_row),k)/numel(node_row); 
    average(:,5,k)=sumation(:,5,numel(node_row),k)/numel(node_row); 
    average(:,6,k)=sumation(:,6,numel(node_row),k)/numel(node_row); 
    average(:,7,k)=sumation(:,7,numel(node_row),k)/numel(node_row); 
    average(:,8,k)=sumation(:,8,numel(node_row),k)/numel(node_row); 
end

for k=1:numel(nsample)
 filename1 = [Comment4 '_nsample' num2str(nsample(1,k)) '_Average_Statistics' '.xlsx'];
 sheet=1;
 writematrix(average(:,:,k),filename1,'Sheet',sheet,'Range','R1');
end

