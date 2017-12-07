const THREE = require('./../../../node_modules/three/build/three.js');

var container;
var camera, scene, renderer;


init();
animate();

function init() {
    container = document.getElementById( 'container' );
    //

    // Load the background texture
    var texture = THREE.ImageUtils.loadTexture( 'test.png' );
    var backgroundMesh = new THREE.Mesh(
        new THREE.PlaneGeometry(2, 2, 0),
        new THREE.MeshBasicMaterial({
            map: texture
        }));

    backgroundMesh .material.depthTest = false;
    backgroundMesh .material.depthWrite = false;

    // Create your background scene
    scene = new THREE.Scene();
    camera = new THREE.Camera();
    scene .add(camera );
    scene .add(backgroundMesh );

    //
    renderer = new THREE.WebGLRenderer( { antialias: false, alpha : false } );
    renderer.setClearColor(0x000000, 0);
    
    renderer.setPixelRatio( window.devicePixelRatio );
    renderer.setSize( window.innerWidth, window.innerHeight );
    // renderer.gammaInput = true;
    // renderer.gammaOutput = true;
    container.appendChild( renderer.domElement );
    //
    window.addEventListener( 'resize', onWindowResize, false );
}

function onWindowResize() {
    //camera.aspect = window.innerWidth / window.innerHeight;
    //camera.updateProjectionMatrix();
    renderer.setSize( window.innerWidth, window.innerHeight );
}

function animate() {
    requestAnimationFrame( animate );
    render();
}

function render() {
    var time = Date.now() * 0.001;
    renderer.render( scene, camera );
}