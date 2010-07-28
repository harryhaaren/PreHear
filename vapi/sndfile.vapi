[CCode (cheader_filename="sndfile.h", lower_case_cprefix="sf_", upper_case_cprefix="SF_")]
namespace SndFile
{
	[CCode (cname="int", cprefix="SFM_")]
	public enum FileMode
	{    
		READ    = 0x10,
		WRITE    = 0x20,
		RDWR    = 0x30,
	}

	[CCode (cname="int")]
	public enum Ambisonic
	{
		NONE        = 0x40,
		B_FORMAT    = 0x41
	}

	[CCode (cname="int")]
	public const bool TRUE;

	[CCode (cname="int")]
	public const bool FALSE;

	/* Extract of format enum */
	[CCode (cname="int")]
	public enum Format
	{
		WAV,                              /* Microsoft WAV format (little endian default). */
		AIFF,                             /* Apple/SGI AIFF format (big endian). */
		AU                                /* Sun/NeXT AU format (big endian). */
	}

	[CCode (default_value = "0UL")]
	[IntegerType (rank = 9)]
	public struct count_t
	{
	}

	[CCode (cname="SF_INFO", has_copy_function = false, has_destroy_function = false)]
	public struct Info
	{
		public count_t frames;
		public int samplerate;
		public int channels;
		public int format;
		public int sections;
		public int seekable;
	}

	[Compact]
	[CCode (cname="SNDFILE", free_function="sf_close")]
	public class File
	{
		[CCode (cname="sf_open")]
		public static File? open (string path, FileMode mode, out SndFile.Info info);
		
		
		// sf_count_t	sf_read_float	(SNDFILE *sndfile, float *ptr, sf_count_t items) ;
		[CCode (cname="sf_read_float")]
		public count_t read_float(float *array,count_t numSamples);
	}
}

