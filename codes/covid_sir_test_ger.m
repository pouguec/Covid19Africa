%%%%covid simulation, DN(PB)^2%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
close all;


t_span = 0:41; % 0:120
ger = [16 16 16 16 16 16 16 16 16 16 18 26 48 74 79 130 165 203 262 545 670 800 ...
      1040 1224 1565 1966 2745 3675 4599 5813 7272 9367 12327 15320 19848 22364 24873 ...
       29056 32991 37323 43938 50871];  %%%real data, will put it in a file and read it from there
pop = 81465971;
y0 = [1; ger(1)/pop; 0; 0; 0];%0] ;  %%% S(0) = 1, I_wos(0) = 1/15.86e6; I_ws(0) = I_h(0) = R(0) = 0
[t,y] = ode45(@covid_sir,t_span, y0);  %solver




%%%%%%%plotting%%%%%%%%%
figure(1)
plot(t, pop*(y(:,3) + y(:,4)),'-ob' , 'MarkerSize',3,'LineWidth',2)
hold on
plot(0:(length(ger) - 1), ger, '-+k', 'MarkerSize',3,'LineWidth',2)
title('Germany');
legend('I_{ws} + I_{h}', 'real numbers', 'FontWeight', 'bold', 'FontSize', 12)
xlabel('Days since 1st case', 'FontWeight', 'bold', 'FontSize', 12);
ylabel('# of cases', 'FontWeight', 'bold', 'FontSize', 12);

%%%%Plotting all type of infections + real data
figure(2)
plot(t, pop*(y(:,2) + y(:,3) + y(:,4)),'-ob' , 'MarkerSize',3,'LineWidth',2)
hold on
plot(t, pop*(y(:,2)),'-xm' , 'MarkerSize',3,'LineWidth',2)
hold on
plot(t, pop*( y(:,3)),'--og' , 'MarkerSize',3,'LineWidth',2)
hold on
plot(t, pop*( y(:,4)),'--xr' , 'MarkerSize',3,'LineWidth',2)
hold on
plot(t,ger, '-+k', 'MarkerSize',3,'LineWidth',2) %% this line needs to be commented out if days > length(ger)
% hold on
% plot(t, exp(0.23*t), '-xb', 'MarkerSize',10,'LineWidth',2) %% Ignore this for now
title('Germany');
legend('Tot. inf. model','I_{wos}', 'I_{ws}','I_h', 'real numbers' , 'FontWeight', 'bold', 'FontSize', 12) %,, 'real numbers'
xlabel('Days since 1st case', 'FontWeight', 'bold', 'FontSize', 12);
ylabel('# of cases', 'FontWeight', 'bold', 'FontSize', 12);




%%%%%%%%%%%%%%Plotting total infections, Susceptible and  Recovered, only makes sense if plotting in the long term%%%%%%%%%%%%%
t_span_long = 0:300;
[t,y_long] = ode45(@covid_sir,t_span_long, y0);  %solver

figure(3)
plot(t, pop*(y_long(:,2) + y_long(:,3) + y_long(:,4)),'-ob' , 'MarkerSize',3,'LineWidth',2)
hold on
plot(t, pop*(y_long(:,1)),'-+m' , 'MarkerSize',3,'LineWidth',2)
hold on
 plot(t, pop*( y_long(:,5)),'-xg' , 'MarkerSize',3,'LineWidth',2)
hold on
%plot(t, exp(0.23*t), '-xb', 'MarkerSize',10,'LineWidth',2)
title('Germany');
legend('Tot. inf. model','Suscep.', 'Receovered', 'FontWeight', 'bold', 'FontSize', 12)
xlabel('Days since 1st case', 'FontWeight', 'bold', 'FontSize', 12);
ylabel('# of cases', 'FontWeight', 'bold', 'FontSize', 12);
%%%%%%%%%

writematrix(y,'solution_data_ger/data_germany_r_temp_split_42days.xls')
writematrix(y_long,'solution_data_ger/data_germany_r_temp_split_301days.xls')

function dydt = covid_sir(t,y)
%% SIR with vital dynamics for covid
%%% S = y(1) susceptible: dS/dt = 
%  I_wos = y(2)
%  I_ws = y(3)
% I_h = y(4)
% R = y(5)
% F = y(6)
%\mu_birth = mu_b
%\mu_death =mu_d
% 
% 
% 
%
%
   mu_b =2.28e-5;
   mu_d = 11/(1000 * 365);
   r_vacc = 0.0;
   mu_imm = 2.74e-3;
   beta_wos = 3./10.*(t<=45) + 3.5/20 *(t>45);
   beta_ws = beta_wos/2.;
   beta_h = beta_wos/10.;   %beta_wos/10.;
   r_wos = 0.30; 
   T_rwos = 10.;
   T_inc = 5.1;
   d_ws = 0.01/100;
   T_f = 5;
   r_ws = .81;
   T_rws = 14.;
   T_ser = 7.;
   d_h = .72/100;
   T_rh = 20;
   a = 2.;
   
   
   dS =  -y(1) * (beta_wos * y(2) + beta_ws * y(3) + beta_h * y(4) ) + mu_imm * y(5) ...
          + mu_b  ... %* (y(1) + y(5)) to be added in front of mu_b (currently assuming I can give birth)
          - mu_d * y(1) - r_vacc * y(1);  
      
   dI_wos = y(1) * (beta_wos * y(2) + beta_ws * y(3) + beta_h * y(4) )- r_wos *y(2) / (T_rwos) ...
            - (1 - r_wos) * y(2) /T_inc  - mu_d * y(2);
        
   dI_ws =  (1 - r_wos) * y(2) /T_inc  - d_ws * y(3) /T_f  ...
            - (1 - d_ws)*  y(3) * ( r_ws / T_rws + (1 - r_ws) / T_ser) - mu_d * y(3);
             
   dI_h = (1 - d_ws)* (1 - r_ws) * y(3) / T_ser  - d_h * y(4) / (a * T_f)  ...
           - (1 - d_h) * y(4) /T_rh  - mu_d * y(4);       
   
   dR = r_wos * y(2) / (T_rwos) + (1 - d_ws)* r_ws * y(3) / T_rws  + (1 - d_h) * y(4) /T_rh  ...
        + r_vacc * y(1) - (mu_imm + mu_d) * y(5);
    
 %  dF =  mu_d + d_ws / T_f * y(3) + d_h * y(4) / (a * T_f) % to be
 %  uncommented to see deaths
   
   

    
    dydt = [dS; dI_wos; dI_ws; dI_h; dR];% dF];
end