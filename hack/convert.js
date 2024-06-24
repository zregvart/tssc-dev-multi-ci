
var fs = require('fs')

var out = function (d) {
    process.stdout.write(d + '\n');
  };

var log = function (d) {
    process.stderr.write(d + '\n');
  };
 
log ( process.argv[2]) 


function expandStep(steps, replacements) {
    var lines = steps.script
    if (lines) {
        for (replace of Object.keys(replacements)) {
            const replaceText = "\$(" + replace + ")" 
            lines = lines.replaceAll(replaceText, replacements[replace])
        }
        return lines
    }
    lines = steps.command
    log ("COMMAND=" + lines)
    return lines [0]
}


function convert_task(task) { 
    const task_name= task.metadata.name
    const params=task.spec.params
    const results=task.spec.results

    // replace results with local file path 
    
    const replacements = new Object()
    if (results) {
        for (r of results) {
            const key = "results." + r.name + ".path" 
            replacements[key] = "./results/" + r.name
        }
    }
    out ("#!/bin/bash")
    out ("# " + task_name)
    out ("mkdir -p ./results")
    out ("")
    out ("# Top level parameters ")
    for(  p of params) {
        exp= (task_name+"_PARAM_" + p.name).toUpperCase().replaceAll ("-", "_").replaceAll(".", "_")
        out ("export " + exp + "=") 
    }
    out ("")
    steps=task.spec.steps
    idx=0
    for (p of steps) {
        out("")
        out("function " + p.name + "() {")
        out('\techo "Running  ' + p.name + '"')

        var lines = expandStep(steps[idx],replacements)
        lines = lines.split('\n');
        for (const line of lines) {
            out("\t" + line)
        }
        out("}")
        idx++
    }

    out ("")
    out ("# Task Steps ")
    steps = task.spec.steps
    if (steps) {
        for (p of steps) {
            out(p.name)
        }
    }
}

fs.readFile(process.argv[2], function(err, data) {
    var scriptfile = {};
    if (err) {
        console.log('No scriptfile.json found ('+err+'). Using default scriptfile');
    } else {
        try {
            scriptfile = JSON.parse(data.toString('utf8',0,data.length));

            convert_task (scriptfile)
        } catch (e) {
            console.log('Error parsing scriptfile.json: '+e);
            process.exit(1);
        }
    } 
});