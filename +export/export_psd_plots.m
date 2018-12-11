function params = export_psd_plots(varargin)
    x = DMExportPlots(varargin{:});
    if(nargin == 0)
        params = x.params;
    else
        params = isa(x,'DMExportPlots');
    end
end