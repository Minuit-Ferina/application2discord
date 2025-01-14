includes=( )
cmd="cpp"


mkdir -p dist

for include in ${includes[@]}; do
	params="${params} -I$include"
done


version=`git describe --tags`

src=("application2discord.lsl")

function build_script() {
	output_file="dist/${1%.lsl}.min.lsl"
	input_file="$1"

	# if [ "$output_file" -ot "$input_file" ] || [ ! -f "$output_file" ]; then
		echo building $1
		"$cmd" $params -o dist/$1 src/$1
		python opt/bin/LSL-PyOptimizer/main.py --output=$output_file dist/$1 -O +EnableSwitch,+ShrinkNames
	# fi
}

for str in ${src[@]}; do
	build_script ${str}
done

# read -p "Press any key..."
