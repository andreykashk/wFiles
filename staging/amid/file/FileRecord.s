( function _FileRecord_s_() {

'use strict';

if( typeof module !== 'undefined' )
{

  require( './FileBase.s' );

}

if( wTools.FileRecord )
return;

wTools.assert( !wTools.FileRecord );

//

/*

!!! add test case to avoid

var r = _.FileRecord( "/pro/app/file/deck/brillig", { relative : '/pro/app' } );
expected r.absolute === "/pro/app/file/deck/brillig"
got r.absolute === "/pro/app/brillig"
gave spoiled absolute path

- time measurements out of test
- tmp -> temp.tmp
- all temp -> temp.tmp
- tests

*/

//

var _ = wTools;
var Parent = null;
var Self = function wFileRecord( o )
{
  if( !( this instanceof Self ) )
  if( o instanceof Self )
  {
    _.assert( arguments.length === 1 );
    return o;
  }
  else
  return new( _.routineJoin( Self, Self, arguments ) );
  return Self.prototype.init.apply( this,arguments );
}

Self.nameShort = 'FileRecord';

//

function init( pathFile, o )
{
  var record = this;

  _.instanceInit( record );

  _.assert( arguments.length === 1 || arguments.length === 2 );
  _.assert( !( arguments[ 0 ] instanceof _.FileRecordOptions ) || arguments[ 1 ] instanceof _.FileRecordOptions );
  _.assert( _.strIs( pathFile ),'_fileRecord expects string ( pathFile ), but got',_.strTypeOf( pathFile ) );

  if( o === undefined )
  o = new _.FileRecordOptions();
  else if( _.mapIs( o ) )
  o = new _.FileRecordOptions( o );

  if( o.strict )
  Object.preventExtensions( record );

  return record._fileRecord( pathFile,o );
}

//

function _fileRecord( pathFile,o )
{
  var record = this;

  _.assert( _.strIs( pathFile ),'_fileRecord :','( pathFile ) must be a string' );
  _.assert( arguments.length === 2 );
  _.assert( o instanceof _.FileRecordOptions,'_fileRecord expects instance of ( FileRecordOptions )' );
  _.assert( o.fileProvider instanceof _.FileProvider.Abstract );

  var isAbsolute = _.pathIsAbsolute( pathFile );
  if( !isAbsolute )
  _.assert( _.strIs( o.relative ) || _.strIs( o.dir ),'( FileRecordOptions ) expects ( dir ) or ( relative ) option or absolute path' );

  /* path */

  if( !isAbsolute )
  if( o.dir )
  pathFile = _.pathJoin( o.dir,pathFile );
  else if( o.relative )
  pathFile = _.pathJoin( o.relative,pathFile );
  else if( !_.pathIsAbsolute( pathFile ) )
  throw _.err( 'FileRecord expects ( dir ) or ( relative ) option or absolute path' );

  pathFile = _.pathRegularize( pathFile );

  /* record */

  record.fileProvider = o.fileProvider;
  if( o.relative )
  record.relative = _.pathRelative( o.relative,pathFile );
  else
  record.relative = _.pathName({ path : pathFile, withExtension : 1 });

  _.assert( record.relative[ 0 ] !== '/' );

  // if( record.relative[ 0 ] !== '.' )
  // if( !_.strBegins( record.relative,'./' ) )
  // record.relative = './' + record.relative;
  record.relative = _.pathDot( record.relative );

  if( o.relative )
  record.absolute = _.pathResolve( o.relative,record.relative );
  else
  record.absolute = pathFile;

  record.absolute = _.pathRegularize( record.absolute );

  // logger.log( 'record.absolute',record.absolute );

  record.real = record.absolute;

  record.ext = _.pathExt( record.absolute );
  record.extWithDot = record.ext ? '.' + record.ext : '';
  record.dir = _.pathDir( record.absolute );
  record.name = _.pathName( record.absolute );
  record.nameWithExt = record.name + record.extWithDot;

  /* */

  _.assert( record.inclusion === null );

  /* */

  if( o.resolvingTextLink ) try
  {
    record.real = _.pathResolveTextLink( record.real );
  }
  catch( err )
  {
    record.inclusion = false;
  }

  /* */

  if( record.inclusion !== false )
  try
  {

    record.stat = o.fileProvider.fileStat
    ({
      pathFile : record.real,
      resolvingSoftLink : o.resolvingSoftLink,
    });

  }
  catch( err )
  {

    record.inclusion = false;
    if( o.fileProvider.fileStat( record.real ) )
    {
      throw _.err( 'Cant read :',record.real,'\n',err );
    }

  }

  /* */

  if( record.stat )
  record.isDirectory = record.stat.isDirectory(); /* isFile */

  // if( record.relative.indexOf( 'x' ) !== -1 )
  // {
  //   console.log( 'record.relative :',record.relative );
  //   debugger;
  // }

  /* */

  if( record.inclusion === null )
  {

    record.inclusion = true;

    _.assert( o.exclude === undefined, 'o.exclude is deprecated, please use mask.excludeAny' );
    _.assert( o.excludeFiles === undefined, 'o.excludeFiles is deprecated, please use mask.maskFiles.excludeAny' );
    _.assert( o.excludeDirs === undefined, 'o.excludeDirs is deprecated, please use mask.maskDirs.excludeAny' );

    var r = record.relative;
    if( record.relative === '.' )
    r = record.nameWithExt;

    // console.log( 'o.maskAll',o.maskAll );

    if( record.relative !== '.' || !record.isDirectory )
    if( record.isDirectory )
    {
      if( record.inclusion && o.maskAll )
      record.inclusion = _.RegexpObject.test( o.maskAll,r );
      if( record.inclusion && o.maskDir )
      record.inclusion = _.RegexpObject.test( o.maskDir,r );
    }
    else
    {
      if( record.inclusion && o.maskAll )
      record.inclusion = _.RegexpObject.test( o.maskAll,r );
      if( record.inclusion && o.maskTerminal )
      record.inclusion = _.RegexpObject.test( o.maskTerminal,r );
    }

  }

  /* */

  if( record.inclusion === true )
  if( o.notOlder !== null )
  {
    debugger;
    logger.log( 'o',o );
    logger.log( 'o.notOlder',o.notOlder );
    throw _.err( 'not tested' );
    record.inclusion = record.stat.mtime <= o.notOlder;
  }

  if( record.inclusion === true )
  if( o.notNewer !== null )
  {
    debugger;
    throw _.err( 'not tested' );
    record.inclusion = record.stat.mtime >= o.notNewer;
  }

  /* */

  if( o.safe || o.safe === undefined )
  {
    if( record.stat && record.inclusion )
    if( !_.pathIsSafe( record.absolute ) )
    {
      debugger;
      throw _.err( 'Unsafe record :',record.absolute,'\nUse options ( safe:0 ) if intention was to access system files.' );
    }

    if( record.stat && !record.stat.isFile() && !record.stat.isDirectory() && !record.stat.isSymbolicLink() )
    throw _.err( 'Unsafe record, unknown kind of file :',record.absolute );

  }

  /* */

  if( o.onRecord )
  {
    var onRecord = _.arrayAs( o.onRecord );
    for( var o = 0 ; o < onRecord.length ; o++ )
    onRecord[ o ].call( record );
  }

  /* */

  if( o.verbosity )
  {

    if( !record.stat )
    logger.log( '!','cant access file :',record.absolute );

  }

  /* */

  _.assert( record.nameWithExt.indexOf( '/' ) === -1,'something wrong with filename' );
  _.assert( record.relative.indexOf( '//' ) === -1,record.relative );

  return record;
}

_.accessorForbid( _fileRecord, { defaults : 'defaults' } );

// _fileRecord.defaults =
// {
//   fileProvider : null,
//
//   pathFile : null,
//   dir : null,
//   relative : null,
//   // dir : null,
//   // relative : null,
//
//   maskAll : null,
//   maskTerminal : null,
//   maskDir : null,
//
//   notOlder : null,
//   notNewer : null,
//
//   onRecord : null,
//
//   safe : 1,
//   verbosity : 0,
//
//   resolvingSoftLink : 0,
//   resolvingTextLink : 0,
// }

//

function fileRecords( records,o )
{

  _.assert( arguments.length === 1 || arguments.length === 2 );
  _.assert( _.strIs( records ) || _.arrayIs( records ) || _.objectIs( records ) );

  if( !_.arrayIs( records ) )
  records = [ records ];

  /**/

  for( var r = 0 ; r < records.length ; r++ )
  {

    if( _.strIs( records[ r ] ) )
    records[ r ] = Self( records[ r ],o );

  }

  /**/

  records = records.map( function( record )
  {

    if( _.strIs( record ) )
    return Self( record,o );
    else if( _.objectIs( record ) )
    return record;
    else throw _.err( 'expects record or path' );

  });

  return records;
}

// fileRecords.defaults = _fileRecord.defaults;
_.accessorForbid( _fileRecord, { defaults : 'defaults' } );

//

function fileRecordsFiltered( records,o )
{
  _.assert( arguments.length === 1 || arguments.length === 2 );

  var records = fileRecords( records,o );

  records = records.filter( function( record )
  {

    return record.inclusion && record.stat;

  });

  return records;
}

// fileRecordsFiltered.defaults = _fileRecord.defaults;
_.accessorForbid( _fileRecord, { defaults : 'defaults' } );

//

function fileRecordToAbsolute( record )
{

  if( _.strIs( record ) )
  return record;

  _.assert( _.objectIs( record ) );

  var result = record.absolute;

  _.assert( _.strIs( result ) );

  return result;
}

//

function changeExt( ext )
{
  var record = this;

  _.assert( arguments.length === 1 );

  var was = record.absolute;

  record.ext = ext;
  record.extWithDot = '.' + ext;

  record.relative = _.pathChangeExt( record.relative,ext );
  record.absolute = _.pathChangeExt( record.absolute,ext );
  record.nameWithExt = _.pathChangeExt( record.nameWithExt,ext );

  /*logger.log( 'pathChangeExt : ' + was + ' -> ' + record.absolute );*/

}

// --
//
// --

var Composes =
{

  relative : null,
  absolute : null,
  real : null,
  dir : null,

  isDirectory : null,
  inclusion : null,

  // safe : true,

  // maskAll : null,
  // maskTerminal : null,
  // maskDir : null,

  // onRecord : null,

  /* derived */

  ext : null,
  extWithDot : null,
  name : null,
  nameWithExt : null,
  hash : null,

}

var Aggregates =
{
  stat : null,
}

var Associates =
{
  fileProvider : null,
}

var Restricts =
{
}

var Statics =
{
}

// --
// prototype
// --

var Proto =
{

  init : init,

  _fileRecord : _fileRecord,
  fileRecordToAbsolute : fileRecordToAbsolute,

  fileRecords : fileRecords,
  fileRecordsFiltered : fileRecordsFiltered,

  changeExt : changeExt,

  /**/

  constructor : Self,
  Composes : Composes,
  Aggregates : Aggregates,
  Associates : Associates,
  Restricts : Restricts,
  Statics : Statics,

}

//

_.protoMake
({
  constructor : Self,
  parent : Parent,
  extend : Proto,
});

//

_.accessorForbid( Self.prototype,
{
  path : 'path',
  file : 'file',
});

//

if( _global_.wCopyable )
wCopyable.mixin( Self );

//

if( typeof module !== 'undefined' )
{

  require( './FileRecordOptions.s' );

}

//

// _.mapExtendFiltering( _.filter.atomicSrcOwn(),Self.prototype,Composes );
_.assert( !_global_.wFileRecord,'wFileRecord already defined' );

if( typeof module !== 'undefined' )
module[ 'exports' ] = Self;

// _global_[ Self.name ] = wTools[ Self.nameShort ] = Self;
wTools[ Self.nameShort ] = Self;
return Self;

})();
