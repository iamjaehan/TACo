nSet = [3, 5,7,10,13];
mSet = [3, 10, 30, 100];
% nSet = 4;
% mSet = 24;
gamma = 0.9;
epsilon = 0.1;
iteration = 100;
d0 = 1;

timeRecord = zeros(length(nSet), length(mSet), iteration);
roundRecord = zeros(length(nSet), length(mSet), iteration);
cycleStep = zeros(length(nSet), length(mSet), iteration);

for i = nSet
    for j = mSet
        for ii = 1:iteration
            n = i;
            m = j;
            C = rand(n,m);
            b = rand(n,1);
            if mod(ii,10) == 0
                disp([num2str(i)+", "+num2str(j)+", "+num2str(ii)])
            end
            disp([num2str(i)+", "+num2str(j)+", "+num2str(ii)])
            tic
            [~,~,~,rounds,maxCycleStep] = TACo(C, b, d0, gamma, epsilon);
            time = toc;
            % timeRecord(find(nSet==i),find(mSet==j),ii) = timeRecord(find(nSet==i),find(mSet==j)) + time;
            timeRecord(find(nSet==i),find(mSet==j),ii) = time;
            roundRecord(find(nSet==i),find(mSet==j),ii) = rounds;
            cycleStep(find(nSet==i),find(mSet==j),ii) = maxCycleStep;
        end
    end
end

% timeRecord = timeRecord./iteration;

% figure(1); clf;
% mesh(nSet, mSet,log10(timeRecord))
% xlabel("n")
% ylabel("m")
% zlabel("logtime [s]")
%%
markers = {'o','s','^','d'};
colors  = lines(4);

figure(2)
clf
ax = gca;
hold on

h = gobjects(4, 1);
for i = 1:4
    localInfo = roundRecord(i,:,:);
    mu = mean(localInfo, 3);
    se = std(localInfo, [], 3) / sqrt(iteration);
    c  = colors(i, :);

    % Shaded uncertainty region (mean ± SEM)
    fill([mSet fliplr(mSet)], ...
         [mu+se  fliplr(mu-se)], ...
         c, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    % Mean line with marker
    h(i) = plot(mSet, mu, '-', 'Marker', markers{i}, 'Color', c, ...
         'LineWidth', 2, 'MarkerSize', 8, ...
         'MarkerFaceColor', c, 'MarkerEdgeColor', 'k');
end

grid on
xlabel("Number of choices ($m$)", 'Interpreter', 'latex')
ylabel("Number of rounds", 'Interpreter', 'latex')
set(gca, 'YScale', 'log', 'XScale', 'log', 'FontName', 'times', 'FontSize', 18)
set(gcf, 'Position', [100 100 800 450])
legend(h, {"$n = 3$","$n = 5$","$n = 7$","$n = 10$"}, ...
       "Location", "northwest", 'Interpreter', 'latex');
set(gca, 'FontName', 'times', 'FontSize', 20)
xlim([2.3 130])
ylim([3 10000])
exportgraphics(gca, './tacoComplex.pdf', 'Resolution', 300)

% figure(3)
% clf
% for i = 1:3
%     localInfo = roundRecord(i,:,:);
%     % localInfo = timeRecord(i,:,:);
%     errorbar(mSet, mean(localInfo,3), std(localInfo,[],3),'LineWidth',3)
%     hold on
% end
% grid on
% ub = zeros(1,length(mSet));
% ub_temp = zeros(1,length(mSet));
% for i = 1:length(mSet)
%     m = mSet(i);
%     n = 3;
%     C = 3;
%     ub_temp(i) = log(1/(m+1)/d0/(n-1))/log(gamma);
%     % ub(i) = ub_temp(i) * (m+1) * n * m / 10;
%     % ub(i) = ub_temp(i) * (n+1) * n * n / 10000;
%     % ub(i) = (m+1) * n * m;
%     % ub(i) = ub_temp(i)*1;
%     ub(i) = ub_temp(i) * 1;
%     for j = 1:n-1
%         m = n;
%         ub(i) = ub(i) * nchoosek(C+m-n+j-1, m-1);
%     end
% end
% plot(mSet,ub,'r--')
% set(gca,'YScale','log','XScale','log')