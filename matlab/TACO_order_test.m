% TACO_order_test.m
% Checks whether play order affects individual outcomes in TACo.
% For each random (C, b) instance, exhaustively runs all n! permutations
% and records each agent's cost/profit by play position.

n = 4; m = 4;
gamma = 0.9; epsilon = 0.1; d0 = 1;
numInstances = 1000;

allPerms = perms(1:n);          % [n! x n]
numPerms = size(allPerms, 1);   % 24

% Per-row storage: one row per (instance x permutation)
totalRows = numInstances * numPerms;
normCostByPos   = zeros(totalRows, n);  % normalized cost of agent at position p
profitByPos     = zeros(totalRows, n);  % profit of agent at position p
rankByPos       = zeros(totalRows, n);  % cost rank (1=cheapest) of agent at position p
profitRankByPos = zeros(totalRows, n);  % profit rank (1=highest profit) of agent at position p

outcomeStable   = false(numInstances, 1);  % true if all perms yield same outcome

rowIdx = 0;
for inst = 1:numInstances
    C = rand(n, m);
    b = rand(n, 1);

    localOutcomes = zeros(numPerms, 1);

    for p = 1:numPerms
        order = allPerms(p, :);

        [outcome, ~, profit, ~, ~] = TACo_ordered(C, b, d0, gamma, epsilon, order);
        localOutcomes(p) = outcome;

        rowIdx = rowIdx + 1;

        costs = C(:, outcome);
        meanC = mean(costs);

        % Cost rank: 1 = lowest cost (best for the agent)
        [~, sortIdx] = sort(costs);
        invCostRank = zeros(n, 1);
        for r = 1:n
            invCostRank(sortIdx(r)) = r;
        end

        % Profit rank: 1 = highest profit (best for the agent)
        profits = profit(:, outcome);
        meanProfit = mean(profits);
        [~, sortIdxP] = sort(profits, 'descend');
        invProfitRank = zeros(n, 1);
        for r = 1:n
            invProfitRank(sortIdxP(r)) = r;
        end

        for pos = 1:n
            agent = order(pos);
            normCostByPos(rowIdx, pos)   = costs(agent) / meanC;
            profitByPos(rowIdx, pos)     = 2 - profits(agent) / meanProfit;
            rankByPos(rowIdx, pos)       = invCostRank(agent);
            profitRankByPos(rowIdx, pos) = invProfitRank(agent);
        end
    end

    outcomeStable(inst) = numel(unique(localOutcomes)) == 1;
end

fprintf('Outcome stable across all permutations: %.1f%% of instances\n', ...
        mean(outcomeStable) * 100);

fs = 15;
fn = 'times';

%% Figure 1+2: Cost and Profit side by side
posLabels = {'1st','2nd','3rd','4th'};

figure(1); clf;
set(gcf, 'Position', [100 100 1200 500]);

subplot(1,2,1);
boxplot(normCostByPos, 'Labels', posLabels, 'Symbol', '');
yline(1, 'k--', 'LineWidth', 1.2);
title('Normalized Cost');
xlabel('Play Position'); ylabel('Cost / Mean Cost');
grid on; set(gca, 'FontSize', fs, 'FontName', fn);

subplot(1,2,2);
boxplot(profitByPos, 'Labels', posLabels, 'Symbol', '');
yline(1, 'k--', 'LineWidth', 1.2);
title('Normalized Profit');
xlabel('Play Position'); ylabel('Relative Profit Advantage');
grid on; set(gca, 'FontSize', fs, 'FontName', fn);
ylim([-2 5])

%% Figure 3: Mean cost rank by play position
figure(3); clf;
meanRank = mean(rankByPos);
semRank  = std(rankByPos);
bar(meanRank); hold on;
errorbar(1:n, meanRank, semRank, 'k.', 'LineWidth', 1.5, 'CapSize', 8);
yline(mean(1:n), 'k--', 'DisplayName', 'Uniform baseline');
xticklabels({'1st','2nd','3rd','4th'});
title('Mean Cost Rank by Play Position');
xlabel('Play Position'); ylabel('Mean Cost Rank  (1 = cheapest)');
legend; grid on; set(gca, 'FontSize', fs, 'FontName', fn);

%% Figure 5: Mean profit rank by play position
figure(5); clf;
meanProfitRank = mean(profitRankByPos);
semProfitRank  = std(profitRankByPos);
bar(meanProfitRank); hold on;
errorbar(1:n, meanProfitRank, semProfitRank, 'k.', 'LineWidth', 1.5, 'CapSize', 8);
yline(mean(1:n), 'k--', 'DisplayName', 'Uniform baseline');
xticklabels({'1st','2nd','3rd','4th'});
title('Mean Profit Rank by Play Position');
xlabel('Play Position'); ylabel('Mean Profit Rank  (1 = highest)');
legend; grid on; set(gca, 'FontSize', fs, 'FontName', fn);

%% Figure 4: Outcome stability
figure(4); clf;
bar([mean(outcomeStable), 1-mean(outcomeStable)]);
xticklabels({'Stable', 'Unstable'});
title('Outcome Stability Across Permutations');
ylabel('Fraction of Instances');
grid on; set(gca, 'FontSize', fs, 'FontName', fn);

% =========================================================================
function [outcome, trade, profit, step, maxCycleLen] = TACo_ordered(C, b, d0, gamma, epsilon, agentOrder)
% Wrapper around TACo logic with a custom agentOrder.

U = 100; %#ok<NASGU>

[n, m] = size(C);
O = zeros(n, m);
P = zeros(n, m);
d = d0;
isConverged = false;
selections = zeros(n, 1);
step = 0;
maxCycleLen = 0;

tol = 1e-3;
stateMap = containers.Map('KeyType','char','ValueType','double');

while ~isConverged
    step = step + 1;
    i = agentOrder(mod(step-1, n) + 1);

    J = b(i) * (O(i,:) - P(i,:)) - C(i,:);
    [~, j_star] = max(J);

    P(i, j_star) = P(i, j_star) + n * d;
    O(:, j_star) = O(:, j_star) + d;
    selections(i) = j_star;

    vec   = [reshape(O - P, 1, []), i];
    vec_q = round(vec / tol);
    key   = mat2str(vec_q);

    found = isKey(stateMap, key);

    if all(selections == selections(1))
        break;
    end

    if found
        firstStep = stateMap(key);
        cycleLen  = step - firstStep;
        if cycleLen > maxCycleLen
            maxCycleLen = cycleLen;
        end

        d = gamma * d;
        stateMap = containers.Map('KeyType','char','ValueType','double');

        allSatisfied = true;
        for k = 1:n
            Jk = b(k) * (O(k,:) - P(k,:)) - C(k,:);
            if max(Jk) - min(Jk) > epsilon
                allSatisfied = false;
                break;
            end
        end

        if allSatisfied
            isConverged = true;
        end
    end

    stateMap(key) = step;
end

outcome = mode(selections);
trade   = O - P;
profit  = diag(b) * (O - P) - C;
end
