function glsl_log(string)
{
  //console.log(string);
}

function glsl_error(string)
{
  console.log(string);
}

function glsl_retrieve_program_variables(gl, program)
{
  program.attributes = {}; 

  var attribute_count = gl.getProgramParameter(program, gl.ACTIVE_ATTRIBUTES);
  
  for (var i = 0; i < attribute_count; i++) 
  {
    var attribute_name = gl.getActiveAttrib(program, i).name;
    glsl_log("Creating attribute handle " + program.name + "."+ attribute_name);
    program.attributes[attribute_name] = gl.getAttribLocation(program, attribute_name);
  }


  program.uniforms = {}; 

  var uniform_count = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);
  
  for (var i = 0; i < uniform_count; i++) 
  {
    var uniform_name = gl.getActiveUniform(program, i).name;
    
    glsl_log("Creating uniform handle " + program.name + "." + uniform_name);

    if (uniform_name.endsWith("[0]"))
	{
	  uniform_name = uniform_name.substring(0, uniform_name.length-3);
	  glsl_log("Cutting out [0] from uniform_name! Result is : " + uniform_name);	  
	}
    
    program.uniforms[uniform_name] = gl.getUniformLocation(program, uniform_name);
  } 
}

function glsl_fetch_compile_shader(gl, programs, program, shader, shader_filename, shader_type)
{
  var xhr = new XMLHttpRequest();
  xhr.open('GET', shader_filename);
  xhr.overrideMimeType('text/plain');

  glsl_log("Requesting shader filename:" + shader_filename + "\n");
  xhr.onload = function () 
  {
    if (xhr.readyState !== 4) return;
    
    if (xhr.status !== 200 && xhr.status !== 0)
    {
      //glsl_log("Error in XHR response for " + shader_filename + " (status = " + xhr.status + ")");
      alert("Error in XHR response for " + shader_filename + " (status = " + xhr.status + ")");
      shader.broken = 1;
      return; 
    }
	
    var shader_string = xhr.response;

    shader = gl.createShader(shader_type);
    gl.shaderSource(shader, shader_string);
    gl.compileShader(shader);
    
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) 
    {
      glsl_error("ERROR: GLSL Shader compilation for file: " + shader_filename + ": " + gl.getShaderInfoLog(shader)); 
    }

    program.shadercount_compiled++; 

    gl.attachShader(program, shader);

    if (program.shadercount_needed == program.shadercount_compiled)
    {
      gl.linkProgram(program);

      if (gl.getProgramParameter(program, gl.LINK_STATUS)) 
      {
	program.complete = 1; 

	glsl_log(program.name + ": GLSL link succeeded!");
	glsl_retrieve_program_variables(gl, program); 

	programs.linked_count++; 

	if (programs.length == programs.linked_count)
	{
	  glsl_log("ALL PROGRAMS LINKED and ready");
	  programs.ready = 1; 
	}
      }
      else
      {
	glsl_error(program.name + "ERROR: GLSL Linker failed" + gl.getProgramInfoLog(program));	
	program.broken = 1;
      }      
    }
  };

  xhr.send();  
}

function glsl_load(gl, programs)
{
  programs.linked_count = 0;   

  for (var i = 0; i < programs.length; i++)
  {
    var program_name = programs[i].name;

    glsl_log("Working on program: " + program_name); 

    programs[program_name] = gl.createProgram(); 

    var p = programs[program_name];

    p.name = program_name; 
    p.shadercount_compiled = 0; 
    p.shadercount_needed = programs[i].vertex_src.length + programs[i].fragment_src.length; 

    p.vertex_shaders = [];

    for (var v = 0; v < programs[i].vertex_src.length; v++)
    {
      glsl_log("Vertex shader #" + v + " has filename " + programs[i].vertex_src[v]); 

      p.vertex_shaders[v] = -1;
      glsl_fetch_compile_shader(gl, programs, p, p.vertex_shaders[v], programs[i].vertex_src[v], gl.VERTEX_SHADER); 
    }    

    p.fragment_shaders = [];

    for (var f = 0; f < programs[i].fragment_src.length; f++)
    {
      glsl_log("Fragment shader #" + f + " has filename " + programs[i].fragment_src[f]); 

      p.fragment_shaders[f] = -1;
      glsl_fetch_compile_shader(gl, programs, p, p.fragment_shaders[f], programs[i].fragment_src[f], gl.FRAGMENT_SHADER); 
    }    
  }
}
