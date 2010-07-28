
/*
	
	This file is part of PreHear. Copyright (c) Harry van Haaren 2010
	
	PreHear is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	PreHear is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with PreHear.  If not, see <http://www.gnu.org/licenses/>.
*/

namespace Audio
{
	public class Sample
	{
		private bool queToggleRecord;
		private int index;
		private int endIndex;
		private float[] array;
		private SndFile.Info info;
		private SndFile.File file;
		
		public Sample()
		{
			this.index = 0;
		}
		
		public void play()
		{
			this.index = 0;
			this.endIndex = this.array.length;
		}
		public void play_x(int x)
		{
			this.index = x * info.samplerate;	// to get seconds
			
			// error check value
			if (this.index > (int) info.frames)
			{
				stdout.printf("WARNING: X position further than start of sample. Playing from start!\n");
				this.index = 0;
			}
			this.endIndex = this.array.length;	// to play till end
		}
		public void play_x_y(int x, int y)
		{
			this.index = x * info.samplerate;					// seconds
			this.endIndex = this.index + y * info.samplerate;	// seconds
			
			// error check the values
			if (this.index > (int) info.frames)
			{
				stdout.printf("WARNING: X position further than start of sample. Playing from start!\n");
				this.index = 0;
			}
			if (this.endIndex > (int) info.frames)
			{
				stdout.printf("WARNING: Y position further than end of sample. Playing till end!\n");
				this.endIndex = (int) info.frames -1;
			}
			
		}
		public bool load_sample(string name)
		{
			//stdout.printf("load_sample(%s)",name);
			
			this.file = SndFile.File.open(name,SndFile.FileMode.READ, out info);
			
			this.array = new float[info.frames];
			this.file.read_float( &this.array[0], info.frames);
			
			//stdout.printf("%s: %i\n", name , (int) info.frames);
			this.index = (int)info.frames;
			
			if (this.index == 0)
				stdout.printf("WARNING: Sample not loaded. Possible uncompatible file?\n");
			
			return true;
		}
		
		public void set_que_record(bool queRecord)
		{
			queToggleRecord = queRecord;
		}
		
		public bool get_que_record()
		{
			return queToggleRecord;
		}
		
		public float[] get_nframes(Jack.NFrames nframes) // nframe parameter
		{
			// create temp array
			float[] tempArray = new float[ (int)nframes ];
			
			// copy contents of real array @ index to tempArray
			for ( int tempIndex =0 ; this.index < this.endIndex && tempIndex < (int) nframes; this.index++)
			{
				tempArray[tempIndex++] = this.array[this.index] ;
			}
			return tempArray;
		}
		
		public float[] get_sample()
		{
			float[] tempArray = new float[this.array.length];
			
			for(int i = 0; i < array.length; i++)
				tempArray[i] = this.array[i];
			
			return tempArray;
		}
		public void clear()
		{
			array = {};
		}
		public void add_sample(float inSample)
		{
			array += inSample;
		}
	}
}

