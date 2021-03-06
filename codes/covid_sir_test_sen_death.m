%%%%covid simulation, DN(PB)^2%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
close all;


t_span = 0:24; % 0:120
y0 = [1; 6.3091e-08; 0; 0; 0; 0] ;  %%% S(0) = 1, I_wos(0) = 1/15.86e6; I_ws(0) = I_h(0) = R(0) = 0
[t,y] = ode45(@covid_sir,t_span, y0);  %solver

sn = [1 2 4 3 3 3 3 3 3 3 8 11 19 24 25 29 36 38 47 56 67, 79,86,99, 105];  %%%real data, will put it in a file and read it from there



%%%%%%%plotting%%%%%%%%%
figure(1)
plot(t, 15.85e6*(y(:,3) + y(:,4)),'-ob' , 'MarkerSize',3,'LineWidth',2)
hold on
plot(0:(length(sn) - 1), sn, '-+k', 'MarkerSize',3,'LineWidth',2)
title('Senegal');
legend('I_{ws} + I_{h}', 'real numbers', 'FontWeight', 'bold', 'FontSize', 12)
xlabel('Days since 1st case', 'FontWeight', 'bold', 'FontSize', 12);
ylabel('# of cases', 'FontWeight', 'bold', 'FontSize', 12);

%%%%Plotting all type of infections + real data
figure(2)
plot(t, 15.85e6*(y(:,2) + y(:,3) + y(:,4)),'-ob' , 'MarkerSize',3,'LineWidth',2)
hold on
plot(t, 15.85e6*(y(:,2)),'-xm' , 'MarkerSize',3,'LineWidth',2)
hold on
plot(t, 15.85e6*( y(:,3)),'--og' , 'MarkerSize',3,'LineWidth',2)
hold on
plot(t, 15.85e6*( y(:,4)),'--xr' , 'MarkerSize',3,'LineWidth',2)
hold on
plot(t,sn, '-+k', 'MarkerSize',3,'LineWidth',2) %% this line needs to be commented out if days > length(sn)
%hold on
%plot(t, exp(0.23*t), '-xb', 'MarkerSize',10,'LineWidth',2) %% Ignore this for now
title('Senegal');
legend('Tot. inf. model','I_{wos}', 'I_{ws}','I_h', 'real numbers' , 'FontWeight', 'bold', 'FontSize', 12) %,, 'real numbers'
xlabel('Days since 1st case', 'FontWeight', 'bold', 'FontSize', 12);
ylabel('# of cases', 'FontWeight', 'bold', 'FontSize', 12);

%%%%
figure(3)
plot(t, 15.85e6*( y(:,6)),'--xr' , 'MarkerSize',3,'LineWidth',2)
hold on


%%%%%%%%%%%%%%Plotting total infections, Susceptible and  Recovered, only makes sense if plotting in the long term%%%%%%%%%%%%%
t_span_long = 0:200;
[t,y_long] = ode45(@covid_sir,t_span_long, y0);  %solver

figure(4)
plot(t, 15.85e6*(y_long(:,2) + y_long(:,3) + y_long(:,4)),'-ob' , 'MarkerSize',3,'LineWidth',2)
hold on
plot(t, 15.85e6*(y_long(:,1)),'-+m' , 'MarkerSize',3,'LineWidth',2)
hold on
plot(t, 15.85e6*( y_long(:,5)),'-xg' , 'MarkerSize',3,'LineWidth',2)
%hold on
%plot(t, exp(0.23*t), '-xb', 'MarkerSize',10,'LineWidth',2)
title('Senegal');
legend('Tot. inf. model','Suscep.', 'Receovered', 'FontWeight', 'bold', 'FontSize', 12)
xlabel('Days since 1st case', 'FontWeight', 'bold', 'FontSize', 12);
ylabel('# of cases', 'FontWeight', 'bold', 'FontSize', 12);
%%%%%%%%%
figure(5)
plot(t, 15.85e6*( y_long(:,6)),'--xr' , 'MarkerSize',3,'LineWidth',2)
hold on


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
   mu_b = 0.01/100;
   mu_d = 2.35e-5;
   r_vacc = 0.0;
   mu_imm = 2.74e-3;
   beta_wos = .37;
   beta_ws =beta_wos/2;
   beta_h = beta_wos/10.;
   r_wos = 0.30;
   T_rwos = 14;
   T_inc = 4;
   d_ws = 0.003;
   T_f = 5;
   r_ws = .81;
   T_rws = 14;
   T_ser = 4.5;
   d_h = 8/100;
   T_rh = 20;
   a = 5.;
   
   
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
    
   dF =    d_ws * y(3)/ T_f  + d_h * y(4) / (a * T_f); % to be
 %  uncommented to see deaths +mu_d
   
   

    
    dydt = [dS; dI_wos; dI_ws; dI_h; dR; dF];
end