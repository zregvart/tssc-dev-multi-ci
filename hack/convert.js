
var fs = require('fs')

var out = function (d) {
    process.stdout.write(d + '\n');
  };

var log = function (d) {
    process.stderr.write(d + '\n');
  };
 
log ( process.argv[2]) 

function convert_task(task) { 
    const task_name= task.metadata.name
    out ("#!/bin/bash")
    out ("# " + task_name)
    params=task.spec.params
    out ("")
    out ("# Top level parameters ")
    for(  p of params) {
        exp= (task_name+"_PARAM_" + p.name).toUpperCase().replaceAll ("-", "_").replaceAll(".", "_")
        out ("export " + exp + "=") 
    }
    out ("")
    steps=task.spec.steps
    idx=0
    for(p of steps) {
        out ("")
        out ("function " + p.name + "() {")  
        
        out ('\techo "Running  ' + p.name  + '"')
        const lines = steps[idx].script.split('\n'); 
        for (const line of lines) {
            out ("\t" + line)
        } 
        out ("}")
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