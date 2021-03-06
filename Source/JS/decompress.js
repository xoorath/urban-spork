// this file is a standalone tool to decompress files in a way we can control a bit easier than if we were just using another third party tool

// the main use case is to decompress something like "mylib_0.035.tar.bz" into a predictable path such as "mylib/" instead of "mylib/mylib_0.035/"
// which would require some knowledge of the version number when loading files in mylib to get the right path.

const colors = require(`colors`);
const decompress = require(`decompress`);
const extract = require('extract-zip');
const fs = require(`fs`);
const mv = require(`mv`);
const path = require(`path`);
const process = require(`process`);

let input = ``;
let output = ``;

let log = txt => { return console.log(`|- ${txt}`.reset); }
let logErr = err => { return console.log(`!- ${err}`.bgRed.white); }

if(process.argv.length >= 3) {
    input = process.argv[2];
} else {
    return logErr(`usage: node decompress.js <archive> <output directory>`);
}

if(process.argv.length >= 4) {
    output = process.argv[3];
} else {
    return logErr(`usage: node decompress.js <archive> <output directory>`);
}

input = path.resolve(input);
output = path.resolve(output);

console.log(`|- running decompression ----------------------------------------------------`.bgBlue.white);
log(`compressed: ${input}`);
log(`decompressed: ${output}`);

function DeleteFolderRecursive(path) {
    if( fs.existsSync(path) ) {
      fs.readdirSync(path).forEach(function(file,index){
        var curPath = path + "/" + file;
        if(fs.lstatSync(curPath).isDirectory()) { // recurse
          DeleteFolderRecursive(curPath);
        } else { // delete file
          fs.unlinkSync(curPath);
        }
      });
      fs.rmdirSync(path);
    }
  };

function DeleteFolder(path) {
    log(`DeleteFolder("${path}")`);
    if(fs.existsSync(path))
    {
        DeleteFolderRecursive(path);
    }
}

function MoveDirectorySafely(fromDir, toDir) {
    log(`move decompressed from: ${fromDir}`);
    log(`move decompressed to: ${toDir}`);
    let tempDir = `${toDir}_temp`;

    function PerformMove(fromDir, toDir, tempDir, context) {
        log(`Performing directory move: ${context}`);
        mv(fromDir, tempDir, {mkdirp:true, clobber:true}, err => {
            if(err) return logErr(`failed to move into temp dir ${err}`);
            log(`removing: ${fromDir}`);
            DeleteFolder(path.resolve(fromDir));
            DeleteFolder(path.resolve(toDir));
            mv(tempDir, toDir, {mkdirp:true, clobber:true}, err => {
               if(err) return logErr(`failed to move from temp dir: ${err}`);
                DeleteFolder(tempDir);
            });
        });
    };

    fs.exists(fromDir, (fromExists) => {
        if(!fromExists) return logErr(`source ${fromDir} doesn't exist.`);
        fs.exists(toDir, (toExists) => {
            if(toExists && (fromDir.indexOf(toDir) === -1)) {
                fs.rmdir(toDir, err => {
                    if(err) return logErr(`couldn't remove dest dir ${toDir}`);
                    
                    fs.exists(tempDir, (tempExists) => {
                        if(tempExists) {
                            fs.rmdir(tempDir, err => {
                                if(err) return logErr(`couldn't remove temp dir ${tempDir}`);
                                PerformMove(fromDir, toDir, tempDir, `toDir and tempDir existed. both were unlinked successfully.`);
                            });
                        } else {
                            PerformMove(fromDir, toDir, tempDir, `toDir existed and was unlinked successfully. tempDir did not exist.`);
                        }
                    });
                });
            }
            else {
                fs.exists(tempDir, (tempExists) => {
                    if(tempExists) {
                        fs.rmdir(tempDir, err => {
                            if(err) return logErr(`couldn't remove temp dir ${tempDir}`);
                            PerformMove(fromDir, toDir, tempDir, `toDir did not exist. tempDir existed and was unlinked successfully.`);
                        });
                    } else {
                        PerformMove(fromDir, toDir, tempDir, `toDir and tempDir did not exist.`);
                    }
                });
            }
        });
    });
}

DeleteFolder(output);

log(`${input} ${output}`);

if(input.endsWith('zip')) {

    if (!fs.existsSync(output)){
        log(`dir does not exist: ${output}`);
        fs.mkdirSync(output);
    }
    else {
        log(`dir does exist: ${output}`);
    }
   
    extract(input, { dir: output, debug: true }, err => {
        if(err) {
            logErr(`extract zip failed: ${err}`);
        }
        else {
            log(`extract zip succeeded. ${output}`);
        }
    });
} else {
    decompress(input, output).then(files => {
        // annoying folder in folder detection
        if(input.endsWith(`tar.bz2`)) {
            let contents = fs.readdirSync(output);
            if(contents.length === 1) {
                if(input.indexOf(contents[0]) !== -1) {
                    let innerPath = path.resolve(output, contents[0]);
                    MoveDirectorySafely(innerPath, path.resolve(innerPath, '../'))
                }
            }
        }
    }).catch(reason =>{
        logErr(`decompress failed, reason: ${reason}`);
    });
}