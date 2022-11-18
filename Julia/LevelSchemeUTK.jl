# This program (levelSchemeUTK) is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Support and maintenance NOT GUARANTEED

# Requires Julia 1.7 or higher

### Dr. Miguel Madurga, University of Tennessee (2021)

using Pkg

isinstalled(pkg::String) = any(x -> x.name == pkg && x.is_direct_dep, values(Pkg.dependencies()))
needed_packages = [
    "Plots", "LaTeXStrings", "JSON"
]

# Check for any needed prerequisite packages, install if not present
println("Checking prerequisites")
for i in needed_packages
    if !(isinstalled(i))
        println("Missing prerequisite package '", i, "' installing!")
        Pkg.add(i)
    end
end

using Plots; 
using LaTeXStrings
using JSON;


#  define annotations for the levels dictionary
global annotationsFonts=[ Plots.font(14,"helvetica",:left,:black), # old level jpi [1]
                   Plots.font(9,"helvetica",:right,:black),        # old level E [2]
                   Plots.font(14,"helvetica",:left,:red),          # new level jpi [3]
                   Plots.font(9,"helvetica",:right,:red),          # new level Energy [4]
                   Plots.font(9,"helvetica",:right,:black),        # old level lifetime [5]
                   Plots.font(9,"helvetica",:right,:red),          # new level lifetime [6]
                   Plots.font(9,"helvetica oblique",:left,:black), #normal gamma line [7]
                   Plots.font(9,"helvetica oblique",:left,:red),   #new gamma line [8]
                   Plots.font(18,"helvetica",:center,:black)       #Nucleus] [9]
                   ]                 

annotationsFonts[7].rotation=70 ; annotationsFonts[8].rotation=70  #gamma transition label angle

# # Dictionary containing levels and transitions information

# # Energy-1 LineColor-2 LineWidth-3 LabelJpi-4 LabelFont-5 LabelE-6 LabelFont-7 labelLifetime-8 lifetimeFont-9
levels=[ 
0     :black 3 L"0^+" annotationsFonts[1] " "         annotationsFonts[2]  " xx ms " annotationsFonts[5] ; #1
1000  :black 1 L"2^+" annotationsFonts[1] "1000 keV"  annotationsFonts[2]  " xx ps " annotationsFonts[5] ; #2
1500  :red   1 L"4^+" annotationsFonts[3] "1500 keV"  annotationsFonts[4]  "  "      annotationsFonts[6] ; #3
2000  :black 1 L"6^+" annotationsFonts[1] "2000  keV" annotationsFonts[2]  "  "      annotationsFonts[5]   #4
] 

# # levelHigh-1 levelLow-2 arrowColor-3 arrowWidth-4 Label-5 labelFont-6
transitions=[
levels[2,1] levels[1,1] :black 1 "1000 keV [E2]"  annotationsFonts[7] ;
levels[3,1] levels[2,1] :red   1 "500 keV"        annotationsFonts[8] ;
levels[4,1] levels[3,1] :black 1 "500 keV"        annotationsFonts[7] ;
levels[4,1] levels[2,1] :black 1 "1000 keV [E2]"  annotationsFonts[7] 
]

# Canvas and position settings
canvasWidth = 80;
canvasLow   = -170             #in keV 
canvasHigh  = 2400             #in keV
goldenRatio = 20/(abs(canvasHigh)+abs(canvasLow)); nucLabel = canvasLow + goldenRatio*(canvasHigh-canvasLow)

levelLineStart = canvasWidth*0.25
levelLineStop  = canvasWidth*0.75

energyShift = 90              #define annotation y position level (keV) 
lineShift   = 30                #define annotation y position gamma line (keV)
canvasShift = 12              #position of initial gamma line with respect of the canvas edge (points)
separation  = 5               #separation between gamma lines

# # the one time we need to define an empty canvas to define the drawing region...

p = plot([],ticks=:false,grid=:false,label=:false,axis=:false,
ylims=(canvasLow,canvasHigh),xlims=(00,canvasWidth)
)

# # Nuclei labels
annotate!([(canvasWidth/2,nucLabel,(L"^{A}_{Z}\textrm{Uub}_{N}",annotationsFonts[9]))])

# # Plot levels and transitions from dictionaries

for i  in eachrow(levels)
    plot!(p, [levelLineStart,levelLineStop], [i[1],i[1]],
    lcolor=i[2],label=:false,linewidth=i[3]
    )
    annotate!([(levelLineStart,i[1]+energyShift,(i[4],i[5])),
    (levelLineStop,i[1]+energyShift-30,(i[6],i[7])),
    (levelLineStop+length(i[8]),i[1],(i[8],i[9]))])
end

for j  in eachrow(transitions)

    plot!(p, [levelLineStop-canvasShift,levelLineStop-canvasShift],[j[1],j[2]],arrow=true,label=false,linecolor=j[3],lw=j[4])
    annotate!([ (levelLineStop-canvasShift,j[1]+lineShift,(j[5],j[6])) ])
    global canvasShift += separation
 
end

# last plot needed to force overlay from for-loops (the loop exists with null, that is, no plot!)
plot!(p)
#savefig("test.pdf")


struct UncertainValue
    value::Float64  # value
    #unc::Float     # uncertainty
    units::String   # units of the value
end

struct State
    energy::Float64          # Energy of the state in keV 
    halflife::UncertainValue

    line_width::Int64        # Width used to draw the line for the label
    line_color::Symbol       # The color used for the line

    label_font::Plots.Font   # Font for the text of the label
    spin_label::String       # Label text for the State's spin parity (2+, etc)
end

struct Isotope
    mass_number::Int64       # mass of the Isotope being drawn
    z::Int64                 # Proton number of the Nucleus
    symbol::String           # Elemental symbol for this Isotope
    symbol_font::Plots.Font  # the font for displaying the isotope label
    levels::Vector{State}    # Levels that this Nuclei has for this scheme

    # all energies are given in keV
    Sn::Float64              # Neutron Separation energy
    S2n::Float64             # 2 Neutron Separation energy
    Sp::Float64              # Proton Separation energy
    S2p::Float64             # 2 Proton Separation energy
    
    Qbeta_minus::Float64     # Energy available for beta - decay in
    Qbetabeta_minus::Float64 # Energy available for double beta - decay
    
    Qbeta_n::Float64         # Energy available for beta delayed neutron emission
    Qbeta_2n::Float64        # Energy available for beta delayed neutron emission
    
    Qalpha::Float64          # Energy available for alpha decay
    
    Qbeta_plus::Float64      # Energy available for beta + decay
    Qbetabeta_plus::Float64  # Energy available for double beta + decay
    
    Qec::Float64             # Energy available for electron capture
    Q2ec::Float64            # Energy available for double electron capture
    
end

struct Transition
    label::String          # the label for the transition
    label_font::Plots.Font # Font used for the Transition label
    
    mother::Isotope        # Mother Nucleus for the Transition
    from::State            # Mother state for the Transition

    daughter::Isotope      # Daughter Nucleus for the Transition
    to::State              # Daughter state for the Transition
end


default_font = Plots.font(9,"helvetica",:right,:black)



Mg32states = [
    State(0,     UncertainValue(86,   "ms"), 3, :black, default_font, L"0^+")
    State(885.3, UncertainValue(11.4, "ps"), 1, :black, default_font, L"2^+")
    State(1058,  UncertainValue(7,    "ns"), 1, :black, default_font, L"0^+")
]

Mg32 = Isotope(32, 12, "Mg", Mg32states, 0,0,0,0,0,0,0,0,0,0,0,0,0)

Al32states = [
    State(0,     UncertainValue(33,   "ms"), 3, :black, default_font, L"1^+")
    State(734.7, UncertainValue(0,    "ps"), 1, :black, default_font, L"(2^+)")
    State(956.6, UncertainValue(200,  "ns"), 1, :black, default_font, L"(4^+)")
]

Al32 = Isotope(32, 13, "Al", Al32states,0,0,0,0,0,0,0,0,0,0,0,0,0)

nuclei_keys = ["Mg32", "Al32"] # build this list to define the order we draw the bands for the nuclei

nuclei      = Dict([("Mg32", Mg32), ("Al32", Al32)]) 



transitions = [
    Transition("", default_font, nuclei["Mg32"], Mg32states[3], nuclei["Mg32"], Mg32states[2])
    Transition("", default_font, nuclei["Mg32"], Mg32states[2], nuclei["Mg32"], Mg32states[1])
    Transition("", default_font, nuclei["Al32"], Al32states[3], nuclei["Al32"], Al32states[2])
    Transition("", default_font, nuclei["Al32"], Al32states[2], nuclei["Al32"], Al32states[1])
]

# get the highest energy level we specify because this sets the scale for the plot
global highestlevel = 0
for i in transitions
    if i.from.energy > highestlevel
        global highestlevel = i.from.energy
    end
    if i.daughter.Sn > highestlevel
        global highestlevel = i.daughter.Sn
    end
end

# load the data file
stringobj = ""
open("testscheme.json") do f
    for line in readlines(f)
        global stringobj = stringobj * line 
    end
end

# parse to a dict object so we can build the objects from it
data = JSON.parse(stringobj)
top_level_required_keys = [
    "config", "isotopes", "fonts", "band_order", "transitions"
]
present_keys = keys(data)
for i in top_level_required_keys
    if !(i in present_keys)
        println("Missing key '", i, "' in supplied json, aborting")
        exit()
    end
end

# these are the minimum keys we need to build a nucleus, if they're not
# present in the JSON, the program exits early
nucleus_required_keys = [
    "mass_number", "z", "symbol", "states"
]
# These keys are optional, if missing, they're initialized to zero
nucleus_optional_keys = [
    "Sn", "S2n", "Sp", "S2p", "Qbeta_minus", "Qbetabeta_minus", "Qbeta_n", "Qbeta_2n",
    "Qalpha", "Qbeta_plus", "Qbetabeta_plus", "Qec", "Q2ec"
]
state_required_keys = [
    "name", "energy", "spin_label"
]
state_optional_keys = [

]
isotopes = Dict{String, Isotope}()
for i in data["isotopes"]
    t_keys = keys(i.second)
    for j in nucleus_required_keys
        if !(j in t_keys)
            t_str = i.first
            println("Isotope '$t_str' missing required key $j")
            exit()
        end
    end
    t_dict = i.second
    # build an args list to unpack and pass 
    args = Vector{Any}(
        t_dict["mass_number"], t_dict["z"], t_dict["symbol"]
    )
    # build the states
    states = Vector{State}()
    for state in i.second["states"]
        # check for required keys

        # check for optional keys that can be filled in automatically

        # fill in special case fields

        # construct state

        # add to states
        
    end

    # build up the list of optional arguments
    for key in nucleus_optional_keys
        if i in t_keys
            
        else

        end
    end
    isotopes[i.first] = Isotope(args...)
    
end
