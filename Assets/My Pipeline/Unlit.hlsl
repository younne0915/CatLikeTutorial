#ifndef MYRP_UNLIT_INCLUDED
#define MYRP_UNLIT_INCLUDED

struct VertexInput {
	float4 pos : POSITION;
};

struct VertexOutput {
	float4 clipPos : SV_POSITION;
};

VertexOutput UnlitPassVertex(VertexInput input) {
	VertexOutput output;
	output.clipPos = input.pos;
	return output;
}

float4 UnlitPassFragment(VertexOutput input) : SV_TARGET{
	return 1;
}

#endif // MYRP_UNLIT_INCLUDED
