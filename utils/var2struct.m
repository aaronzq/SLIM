function s = var2struct(varargin)
vars = varargin;
for i = 1:numel(vars)
    s.(vars{i}) = evalin('caller', vars{i});
end
end