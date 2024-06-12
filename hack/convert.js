
var fs = require('fs')

var out = function (d) {
    process.stdout.write(d + '\n');
  };

var log = function (d) {
    process.stderr.write(d + '\n');
  };
 
log ( process.argv[2]) 

function convert_task(task) { 
    out ("# " + task.metadata.name)
    params=task.spec.params
    out ("")
    out ("# Parameters ")
    for(  p of params) {
        out ("export " + p.name + "=") 
    }
    out ("")
    steps=task.spec.steps
    idx=0
    for(p of steps) {
        out ("")
        out ("function " + p.name + "() {")
        out (steps[idx].name) 
        out ("")
        out (steps[idx].script) 
        out ("}")
        idx++
    }

    out ("")
    out ("# Task Steps ")
    steps=task.spec.steps
    for(p of steps) {
        out (p.name  )
    } 
}

fs.readFile(process.argv[2], function(err, data) {
    var settings = {};
    if (err) {
        console.log('No settings.json found ('+err+'). Using default settings');
    } else {
        try {
            settings = JSON.parse(data.toString('utf8',0,data.length));

            convert_task (settings)
        } catch (e) {
            console.log('Error parsing settings.json: '+e);
            process.exit(1);
        }
    } 
});