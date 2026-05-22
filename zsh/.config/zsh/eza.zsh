# Eza configuration and aliases

# Configure eza if available
if command -v eza &> /dev/null; then
  # Set eza colors with ANSI codes for consistent piped output (Tokyo Night inspired)
  # All codes from: https://github.com/eza-community/eza/blob/main/man/eza_colors.5.md
  export EZA_COLORS=""
  # Permissions
  export EZA_COLORS="${EZA_COLORS}ur=33:uw=31:ux=32:ue=32:gr=33:gw=31:gx=32:tr=33:tw=31:tx=32:su=35:sf=35:xa=36:oc=37"
  # File types
  export EZA_COLORS="${EZA_COLORS}:di=34:ex=32:fi=37:pi=35:so=35:bd=35:cd=35:ln=36:or=31:sp=35:mp=34"
  # File categories
  export EZA_COLORS="${EZA_COLORS}:im=36:vi=33:mu=32:lo=32:cr=32:do=31:co=33:tm=90:cm=33:bu=33:sc=33:ic=36"
  # Size
  export EZA_COLORS="${EZA_COLORS}:sn=37:nb=37:nk=37:nm=37:ng=37:nt=37:sb=37:ub=37:uk=37:um=37:ug=37:ut=37"
  # Device IDs
  export EZA_COLORS="${EZA_COLORS}:df=37:ds=37"
  # Users
  export EZA_COLORS="${EZA_COLORS}:uu=37:uR=31:un=37:gu=37:gR=31:gn=37"
  # Hard links
  export EZA_COLORS="${EZA_COLORS}:lc=37:lm=33"
  # Git status
  export EZA_COLORS="${EZA_COLORS}:ga=32:gm=33:gd=31:gv=36:gt=33:gi=90:gc=31"
  # Git repo
  export EZA_COLORS="${EZA_COLORS}:Gm=34:Go=36:Gc=32:Gd=33"
  # UI/other
  export EZA_COLORS="${EZA_COLORS}:xx=37:da=36:in=37:bl=37:hd=33:lp=36:cc=37:bO=90:ff=37:Sn=37:Su=37:Sr=37:St=37:Sl=37"
fi
