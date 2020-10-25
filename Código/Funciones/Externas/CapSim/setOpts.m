% setOpts - a utility function for setting default parameters
% ===============
% defaults  - either a cell array or a structure of field/default-value pairs.
% options   - either a cell array or a structure of values which override the defaults.
% params    - structure containing the union of fields in both inputs. 
function params = setOpts(defaults,options)

if nargin==1 || isempty(options)
   user_fields  = [];
else
   if isstruct(options)
      user_fields   = fieldnames(options);
   else
      user_fields = options(1:2:end);
      options     = struct(options{:});
   end
end

if isstruct(defaults)
   params   = defaults;
else
   params   = struct(defaults{:});
end

for k = 1:length(user_fields)
   params.(user_fields{k}) = options.(user_fields{k});
end