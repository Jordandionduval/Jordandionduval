//CG Academy HLSL Shader DVD Set
//DVD 2: Shader Lighting Pipelines
//Chapter 1: Normal Mapping

/************* TWEAKABLES **************/

float4 AmbientColor : Ambient
<
    string UIName = "Ambient Color";
> = {0.25f, 0.25f, 0.25f, 1.0f};


float4 DiffuseColor : Diffuse
<
    string UIName = "Diffuse Color";
> = {1.0f, 1.0f, 1.0f, 1.0f};


texture diffuseMap : DiffuseMap
<
    string name = "default_color.dds";
    string UIName = "Diffuse Texture";
    string TextureType = "2D";
>;

texture normalMap : NormalMap
<
    string name = "default_bump_normal.dds";
    string UIName = "Normal Texture";
    string TextureType = "2D";
>;


/************** light info **************/

float4 light1Pos : POSITION
<
    string UIName = "Light Position";
    string Object = "PointLight";
    string Space = "World";
    int refID = 0;
> = {100.0f, 100.0f, 100.0f, 0.0f};


float4 light1Color : LIGHTCOLOR
<
    int LightRef = 0;
> = { 1.0f, 1.0f, 1.0f, 0.0f };





/****************************************************/
/********** SAMPLERS ********************************/
/****************************************************/

sampler2D diffuseMapSampler = sampler_state
{
    Texture = <diffuseMap>;
    AddressU = Wrap;
    AddressV = Wrap;
    MinFilter = linear;
    MagFilter = linear;
    MipFilter = anisotropic;
};


sampler2D normalMapSampler = sampler_state
{
    Texture = <normalMap>;
    AddressU = Wrap;
    AddressV = Wrap;
    MinFilter = linear;
    MagFilter = linear;
    MipFilter = anisotropic;
};


/***********************************************/
/*** automatically-tracked "tweakables" ********/
/***********************************************/

float4x4 WorldViewProjection    : WorldViewProjection   < string UIWidget = "None"; >;
float4x4 WorldInverseTranspose  : WorldInverseTranspose < string UIWidget = "None"; >;
float4x4 ViewInverse            : ViewInverse           < string UIWidget = "None"; >;
float4x4 World                  : World                 < string UIWidget = "None"; >;


/****************************************************/
/********** CG SHADER FUNCTIONS *********************/
/****************************************************/

// input from application
    struct a2v {
    float4 position     : POSITION;
    float2 texCoord     : TEXCOORD0;
    float3 normal       : NORMAL;
    float3 binormal     : BINORMAL;
    float3 tangent      : TANGENT;
};


// output to fragment program
struct v2f {
        float4 position        : POSITION;
        float2 texCoord        : TEXCOORD0;
        float3 lightVec        : TEXCOORD1;
        float3 worldNormal     : TEXCOORD2;
        float3 worldBinormal   : TEXCOORD3;
        float3 worldTangent    : TEXCOORD4;
};



/**************************************/
/***** VERTEX SHADER ******************/
/**************************************/

v2f v(a2v In, uniform float4 lightPosition)
{
    v2f Out;                                                            //create the output struct
    Out.worldNormal = mul(In.normal, WorldInverseTranspose).xyz;        //put the normal in world space pass it to the pixel shader
    Out.worldBinormal = mul(In.binormal, WorldInverseTranspose).xyz;    //put the binormal in world space pass it to the pixel shader
    Out.worldTangent = mul(In.tangent, WorldInverseTranspose).xyz;      //put the tangent in world space pass it to the pixel shader
    float4 worldSpacePos = mul(In.position, World);                     //put the vertex in world space
    Out.lightVec = lightPosition - worldSpacePos;                       //create the world space light vector and pass it to the pixel shader
    Out.texCoord.xy = In.texCoord;                                      //pass the UV coordinates to the pixel shader
    Out.position = mul(In.position, WorldViewProjection);               //put the vertex position in clip space and pass it to the pixel shader
    return Out;
}




/**************************************/
/***** FRAGMENT PROGRAM ***************/
/**************************************/

float4 f(v2f In,uniform float4 lightColor) : COLOR
{
    //fetch the diffuse and normal maps
    float4 ColorTexture = tex2D(diffuseMapSampler, In.texCoord);
    float4 normal = tex2D(normalMapSampler, In.texCoord)*2-1;

    float3 Nn = In.worldNormal;
    float3 Bn = In.worldBinormal;
    float3 Tn = In.worldTangent;

    float3 N = (normal.z * Nn) + (normal.x * Bn) + (normal.y * -Tn);             // In Y-up env, formula would be (normal.z *Nn) + (normal.x * Tn) + (normal.y * -Bn)

    N = normalize(N);

    //create lighting vectors - view vector and light vector
    float3 L = normalize(In.lightVec.xyz);                                      //the light vector must be normalized here so all vectors will be normalized
  
    //lighting
  
    //ambient light
    float4 Ambient = AmbientColor * ColorTexture;                               //To create the ambient term, we multiply the ambient color and the diffuse texture
  
    
    //diffuse light
    float4 diffuselight = saturate(dot(N, L)) * lightColor;                     //To get the diffuse light value we calculate the dot product between the light vector and the normal                               
    float4 Diffuse = DiffuseColor * ColorTexture * diffuselight;                //To get the final diffuse color we multiply the diffuse color by the diffuse texture

    //return Diffuse + Ambient;
    return saturate(dot(N,L)) * lightColor;
}





/****************************************************/
/********** TECHNIQUES ******************************/
/****************************************************/

technique regular
{ 
    pass one 
    {       
        VertexShader = compile vs_1_1 v(light1Pos);                                 //here we call the vertex shader function and tell it we want to use VS 1.1 as the profile                  
        ZEnable = true;                                                             //this enables sorting based on the Z buffer
        ZWriteEnable = true;                                                        //this writes the depth value to the Z buffer so other objects will sort correctly this this one
        CullMode = CW;                                                              //this enables backface culling.  CW stands for clockwise.  You can change it to CCW, or none if you want.
        AlphaBlendEnable = false;                                                   //This disables transparency.  If you make it true, the alpha value of the final pixel shader color will determine how transparent the surface is.
        PixelShader = compile ps_2_0 f(light1Color);                                //here we call the pixel shader function and tell it we want to use the PS 2.0 profile
    }
}



