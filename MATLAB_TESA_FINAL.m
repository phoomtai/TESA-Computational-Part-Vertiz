close all, clear, clc
 
 
 
% % Connect to server
url = 'http://192.168.1.220/height/';
%
% % Read data from server
recieved_data_json = webread(url);
recieved_data_json_H = struct(recieved_data_json.data);
recieved_data = (struct2table(recieved_data_json_H).height).'


 
%%% ASSUMING DATA IS COMING FROM SERVER THIS PART SHOULD BE DELETE %%%

%%% ASSUMING DATA IS COMING FROM SERVER THIS PART SHOULD BE DELETE %%%
 
disp('The Imported data is :')
disp(recieved_data)
 
%% import data from xlsx
data_sheet1 = xlsread('dataset-6a.xlsx',1); % dynamics (compute)
data_sheet2 = xlsread('dataset-6a.xlsx',2); % Static (model)
data_sheet3 = xlsread('dataset-6a.xlsx',3); % Static (model)
 
%% Append data from server to our own data format
data_sheet1_col2 = data_sheet1(:,2);
data_sheet1_col2 = data_sheet1_col2(~isnan(data_sheet1_col2));
data_sheet1_col2 = vertcat(data_sheet1_col2, recieved_data.');
data_sheet1(1:length(data_sheet1_col2),2) = data_sheet1_col2;
 
 
 
%% model Sheet 2 Regression (for data Discharge_S1)
H_S1 = data_sheet2(:,1);
Q_S1 = data_sheet2(:,2);
 
[Q_S1_fil, H_S1_fil] = filter_vertiz(Q_S1, H_S1);
figure('Name','Q-H Curve of Data in sheet No. 2');
subplot(1,2,1);plot(Q_S1,H_S1,'xr');title('Q1-H1 Before Filter');xlabel('Q1');ylabel('H1');
subplot(1,2,2);plot(Q_S1_fil,H_S1_fil,'xb');title('Q1-H1 After Filter');xlabel('Q1');ylabel('H1');
hold on
x = Q_S1_fil; y = H_S1_fil;
% [f_sheet2,para_sheet2] = fit(x,y,'poly1');
% c1 = coeffvalues(f_sheet2);
% x_line = 0:0.001:2000;
% S1_func = @(x) c1(1) * x + c1(2);
% y_pred = c1(1) * x_line + c1(2);
[f_sheet2,para_sheet2] = fit(x,y,'poly2');
c1 = coeffvalues(f_sheet2);
x_line = 0:0.001:2000;
S1_func = @(x) c1(1) * x.^2+ c1(2) * x + c1(3);
y_pred = c1(1) * x_line.^2 + c1(2) * x_line + c1(3);
plot(x_line,y_pred,'g','LineWidth',2);legend('Real data','Prediction');
Discharge_S1_compute = [];
for i = recieved_data
    Discharge_S1_compute = [Discharge_S1_compute S1_func(i)];
end
data_sheet1_col3 = data_sheet1(:,3);
data_sheet1_col3 = data_sheet1_col3(~isnan(data_sheet1_col3));
data_sheet1_col3 = vertcat(data_sheet1_col3, Discharge_S1_compute.');
data_sheet1(1:length(data_sheet1_col3),3) = data_sheet1_col3; % Cat data to S1
hold off
 
%% model Sheet 3 Regression (for data H3)
H_S3 = data_sheet3(:,1);
Q_S3 = data_sheet3(:,2);
figure('Name','Q-H Curve of Data in sheet No. 3')
[Q_S3_fil, H_S3_fil] = filter_vertiz(Q_S3, H_S3);
subplot(1,2,1);plot(Q_S3,H_S3,'xr');title('Q3-H3 Before Filter');xlabel('Q3');ylabel('H3');
subplot(1,2,2);plot(Q_S3_fil,H_S3_fil,'xb');title('Q3-H3 After Filter');xlabel('Q3');ylabel('H3');
 
 
 
%% compute Factor "F" from Q1 : Q2 : Q3
hold off % please delete this
Discharge_S1 = data_sheet1(1:60,3); % !!! NOT Complete NEED to append with Sheet 2 regression part
Discharge_S2 = data_sheet1(1:60,4);
Discharge_S3 = data_sheet1(1:60,5);
Factor = Discharge_S3./(Discharge_S1+Discharge_S2); % iff Q1 + Q2 = Q3/f
Factor = Factor(~isnan(Factor));
Factor_mean = mean(Factor);
 
disp('The "F" Factor is :')
disp(Factor_mean)
 
%% compute Discharge by using "F * Q3" namely, Q4
FQ3 = Discharge_S3 * Factor_mean;

%% model predict Height_S1

Hei_S1_real = data_sheet1(:,2); %เพิ่ม data จาก Server ก่อน
Hei_S1_real = Hei_S1_real(~isnan(Hei_S1_real));
lpd = length(Hei_S1_real);
Hei_S1_Pre = Hei_S1_real;
for i = 1:5
    Hei_S1_Sum =0;
    if i==1
        for j = 0:4
            Hei_S1_Sum = Hei_S1_Sum + Hei_S1_real(length(Hei_S1_real)-j);
        end
        Hei_S1_Pre = [Hei_S1_Pre ; Hei_S1_Sum/5];
    else
        for j = 0:4
            Hei_S1_Sum = Hei_S1_Sum + Hei_S1_Pre(length(Hei_S1_Pre)-j);
        end
        Hei_S1_Pre = [Hei_S1_Pre ; Hei_S1_Sum/5];
    end
end
figure;
hold on
plot(Hei_S1_Pre) 
plot(Hei_S1_real)
legend('Predict','Real');
hold off 
 
 
%% Filter Function
function [Q_filter, H_filter] = filter_vertiz(Q_data,H_data)
for i = 1:length(Q_data)
    if i ==1
       in1 = [0];
       tt = Q_data(i);
    end
    if i>1
       if Q_data(i)<tt
          in1 = [in1 i];
          tt = tt;
       else
          in1 =[in1 0];
          tt = Q_data(i);
       end
    end
end
index_to_del = in1;
index_to_keep = (index_to_del == 0 );
Q_filter = Q_data(index_to_keep);
H_filter = H_data(index_to_keep);
end
%% 
 