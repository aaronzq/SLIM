function [estimate, cvg] = RL_solver_acc(img, VolumeGuess, forward_func, backward_func, iter, verbose)
%%%  Solver for (Light Field) Richardson Lucy Deconvolution
%%%  Input:
%%%      img: raw measurement
%%%      VolumeGuess: estimate initialization
%%%      forward_func, backward_func: forward and backward function handles
%%%                   compatible with img and VolumeGuess/estimate's formats
%%%      iter: number of iterations
%%%      verbose: enable to print every iteration's time
%%%  Output:
%%%      estimate: the estimated signals 
%%%      cvg: convergency
%%%  Author: Zhaoqiang Wang, 2023


    cvg = zeros(iter,1);  
    Xguess = VolumeGuess;
    Yguess = zeros(size(Xguess));
    Vguess_prev = zeros(size(Xguess));  
    for t=1:iter
        if verbose
            tic;
        end
                
        forward_projection = forward_func(Xguess);
        errorBack = img./(forward_projection);
        errorBack(isnan(errorBack)) = 1e-6;errorBack(isinf(errorBack)) = 1e-6;errorBack = max(errorBack, 1e-6);
        back_project_error = backward_func(errorBack);
        Yguess_next = Xguess .* back_project_error;
        Yguess_next = max(Yguess_next, 1e-6);
        
        Vguess = Yguess_next - Xguess;
        Vguess = max(Vguess, 1e-6);
        if t==1
            alpha = 0;
        else
            alpha = sum(Vguess.*Vguess_prev,'all') ./ (sum(Vguess_prev.*Vguess_prev,'all')+eps);
            alpha = max(min(alpha,1),1e-6);
        end
%         alpha = 0;       
        Xguess_next = Yguess_next + alpha*(Yguess_next-Yguess);
        Xguess_next = max(Xguess_next, 1e-6);
        Xguess_next(isnan(Xguess_next)) = 1e-6;
        
        Xguess = Xguess_next;
        Yguess = Yguess_next;
        Vguess_prev = Vguess;
        
        cvg(t) = mean(Vguess(Vguess>0),'all');  
        
        if verbose
            ttime = toc;
            fprintf(['iter ' num2str(t) ' | ' num2str(iter) ', took ' num2str(ttime) ' secs\n']);        
        end

    end
    estimate = Xguess;
    if verbose
        fprintf('Done.\n');
    end
end