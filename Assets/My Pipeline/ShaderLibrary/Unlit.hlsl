#ifndef MYRP_UNLIT_INCLUDED
#define MYRP_UNLIT_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

CBUFFER_START(UnityPerFrame)
float4x4 unity_MatrixVP;
CBUFFER_END

CBUFFER_START(UnityPerDraw)
float4x4 unity_ObjectToWorld;
CBUFFER_END

#define UNITY_MATRIX_M unity_ObjectToWorld

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"


/*
 #define UNITY_INSTANCING_BUFFER_START(buf)      UNITY_INSTANCING_CBUFFER_SCOPE_BEGIN(UnityInstancing_##buf) struct {
	#define UNITY_INSTANCING_BUFFER_END(arr)        } arr##Array[UNITY_INSTANCED_ARRAY_SIZE]; UNITY_INSTANCING_CBUFFER_SCOPE_END

	#define UNITY_INSTANCING_CBUFFER_SCOPE_BEGIN(name)  cbuffer name {
	#define UNITY_INSTANCING_CBUFFER_SCOPE_END          }

	#define UNITY_DEFINE_INSTANCED_PROP(type, var)      type var;
*/
/*
cbuffer UnityInstancing_PerInstance
{
	struct{
	float4 _Color
	} PerInstanceArray[UNITY_INSTANCED_ARRAY_SIZE];
}
*/

//声明一个数组PerInstanceArray，里面存储float4, _Color
UNITY_INSTANCING_BUFFER_START(PerInstance)
UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
UNITY_INSTANCING_BUFFER_END(PerInstance)



struct VertexInput {
	float4 pos : POSITION;
	//声明一个instanceID，当GPU Instance可用时，获取该顶点对应的M 矩阵
	UNITY_VERTEX_INPUT_INSTANCE_ID	//uint instanceID : SV_InstanceID;
		/*
		#   define UNITY_VERTEX_INPUT_INSTANCE_ID DEFAULT_UNITY_VERTEX_INPUT_INSTANCE_ID
		#ifdef SHADER_API_PSSL
		#define DEFAULT_UNITY_VERTEX_INPUT_INSTANCE_ID uint instanceID;
		#define UNITY_GET_INSTANCE_ID(input)    _GETINSTANCEID(input)
	#else
		#define DEFAULT_UNITY_VERTEX_INPUT_INSTANCE_ID uint instanceID : SV_InstanceID;
		#define UNITY_GET_INSTANCE_ID(input)    input.instanceID
	#endif
		*/
};

struct VertexOutput {
	float4 clipPos : SV_POSITION;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};



VertexOutput UnlitPassVertex(VertexInput input) {
	VertexOutput output;
	/*
	#   define UNITY_SETUP_INSTANCE_ID(input) DEFAULT_UNITY_SETUP_INSTANCE_ID(input)
	#define DEFAULT_UNITY_SETUP_INSTANCE_ID(input)          { UnitySetupInstanceID(UNITY_GET_INSTANCE_ID(input));}
		#define UNITY_GET_INSTANCE_ID(input)    input.instanceID

		void UnitySetupInstanceID(uint inputInstanceID)
	{
		#ifdef UNITY_STEREO_INSTANCING_ENABLED
			#if defined(SHADER_API_GLES3)
				// We must calculate the stereo eye index differently for GLES3
				// because otherwise,  the unity shader compiler will emit a bitfieldInsert function.
				// bitfieldInsert requires support for glsl version 400 or later.  Therefore the
				// generated glsl code will fail to compile on lower end devices.  By changing the
				// way we calculate the stereo eye index,  we can help the shader compiler to avoid
				// emitting the bitfieldInsert function and thereby increase the number of devices we
				// can run stereo instancing on.
				unity_StereoEyeIndex = round(fmod(inputInstanceID, 2.0));
				unity_InstanceID = unity_BaseInstanceID + (inputInstanceID >> 1);
			#else
				// stereo eye index is automatically figured out from the instance ID
				unity_StereoEyeIndex = inputInstanceID & 0x01;
				unity_InstanceID = unity_BaseInstanceID + (inputInstanceID >> 1);
			#endif
		#else
			unity_InstanceID = inputInstanceID + unity_BaseInstanceID;
		#endif
	}
	*/

	//计算unity_InstanceID
	UNITY_SETUP_INSTANCE_ID(input);

	/*
		#define UNITY_TRANSFER_INSTANCE_ID(input, output)   output.instanceID = UNITY_GET_INSTANCE_ID(input)
	*/
	//把input里的instanceID赋值给output.instanceID
	UNITY_TRANSFER_INSTANCE_ID(input, output);

	/*
	#define UNITY_MATRIX_M      UNITY_ACCESS_INSTANCED_PROP(unity_Builtins0, unity_ObjectToWorldArray)
		#define UNITY_ACCESS_INSTANCED_PROP(arr, var)   arr##Array[unity_InstanceID].var
		unity_Builtins0Array[unity_InstanceID].unity_ObjectToWorldArray

	*/
	//以unity_InstanceID为下标从数组里取M 矩阵
	float4 worldPos = mul(UNITY_MATRIX_M, float4(input.pos.xyz, 1.0));
	output.clipPos = mul(unity_MatrixVP, worldPos);
	return output;
}

float4 UnlitPassFragment(VertexOutput input) : SV_TARGET{
	//计算unity_InstanceID
	UNITY_SETUP_INSTANCE_ID(input);

	/*
	#define UNITY_MATRIX_M      UNITY_ACCESS_INSTANCED_PROP(unity_Builtins0, unity_ObjectToWorldArray)
	#define UNITY_ACCESS_INSTANCED_PROP(arr, var)   arr##Array[unity_InstanceID].var
	unity_Builtins0Array[unity_InstanceID].unity_ObjectToWorldArray

	*/
	//取数组PerInstance里_Color属性
	return UNITY_ACCESS_INSTANCED_PROP(PerInstance, _Color);
}

#endif // MYRP_UNLIT_INCLUDED
