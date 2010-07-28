
/*
	
	PreHear: Copyright (C)  Harry van Haaren 2010
	
	PreHear is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

extern void exit (int exitCode);


Jack.Client? client;
unowned Jack.Port master_l;
unowned Jack.Port master_r;

Audio.Sample currentSample;
Audio.Volume currentVolume;

bool loading;

Gtk.FileChooser fileChooser;
Gtk.SpinButton spinX;
Gtk.SpinButton spinY;

namespace Audio
{
	public class Volume
	{
		public float volume;
		
		public Volume() {}
		
		public void set_volume(float inVol)
		{
			volume = inVol;
		}
		public float get_volume()
		{
			return volume;
		}
		
		// there's a chance were passed a "null" array, so pass by ref
		public void process( ref float[] input)
		{
			
			for( int i = 0; i < input.length; i++)
			{
				input[i] = (float) (input[i] * this.volume);
			}
		}
	}
}

public int processCallback(Jack.NFrames nframes)
{
	// Output:
	var buffer_l = (float*) master_l.get_buffer(nframes);
	var buffer_r = (float*) master_r.get_buffer(nframes);
	
	float[] recordSamp = {};
	
	if (!loading)
	{
		recordSamp = currentSample.get_nframes(nframes);
	}
	
	for(int i = 0; i < (uint32) nframes; i++)
	{
		float temp = 0;
		
		if (!loading)
			temp += recordSamp[i];
		
		buffer_l[i] = temp;
		buffer_r[i] = temp;
	}
	
	return 0;
}

public void on_playButton_clicked()
{
	loading = true;
	currentSample.load_sample(fileChooser.get_filename());
	stdout.printf("currentSample.play()\n");
	currentSample.play();
	loading = false;
}

public void on_playX_clicked()
{
	loading = true;
	currentSample.load_sample(fileChooser.get_filename());
	stdout.printf("currentSample.playX(%i)\n",spinX.get_value_as_int());
	currentSample.play_x( spinX.get_value_as_int() );
	loading = false;
}
public void on_playXY_clicked()
{
	loading = true;
	currentSample.load_sample(fileChooser.get_filename());
	stdout.printf("currentSample.playXY(%i,%i)\n",spinX.get_value_as_int(),spinY.get_value_as_int());
	currentSample.play_x_y( spinX.get_value_as_int() , spinY.get_value_as_int() );
	loading = false;
}

public int main(string[] args)
{
	Gtk.init(ref args);
	
	// load samples into "Sample" objects (init objects first)
	currentSample = new Audio.Sample();
	
	currentVolume = new Audio.Volume();
	currentVolume.set_volume( (float) 1.0);
	
	try
	{
		var builder = new Gtk.Builder ();
		builder.add_from_file ("ui.glade");
		var window		= builder.get_object ("window"    ) as Gtk.Window;
		var playButton	= builder.get_object ("playButton") as Gtk.Button;
		var playX		= builder.get_object ("playX"     ) as Gtk.Button;
		var playXY		= builder.get_object ("playXY"    ) as Gtk.Button;
		fileChooser		= builder.get_object ("filechooser")as Gtk.FileChooser;
		spinX			= builder.get_object ("spinX")as Gtk.SpinButton;
		spinY			= builder.get_object ("spinY")as Gtk.SpinButton;
		
		var ff = new Gtk.FileFilter();
		ff.add_pattern("*.wav");
		ff.add_pattern("*.au");
		ff.add_pattern("*.aiff");
		
		fileChooser.set_filter(ff);
		
		spinX.set_increments(1.0,1.0);
		spinY.set_increments(1.0,1.0);
		
		spinX.set_range(0.0,15.0);
		spinY.set_range(0.0,15.0);
		
		playButton.clicked.connect( on_playButton_clicked );
		playX.clicked.connect( on_playX_clicked );
		playXY.clicked.connect( on_playXY_clicked );
		
		window.set_title("PreHear");
		window.show_all ();
	}
	catch (Error e)
	{
		stderr.printf ("Could not load UI: %s\n", e.message);
		return 1;
	}
	
	// Set up JACK:
	Jack.Status status;
	
	stdout.printf("Attempting to connect to JACK...\t\t\t");
	client = Jack.Client.open("PreHear",Jack.Options.NoStartServer, out status);
	
	for(int i = 0; client == null; i++) // loop to check JACK is running
	{
		stdout.printf("Failed.\n");
		
		string message = "JACK server is not started, will I start it for you?";
		if (i > 0) // we've already tried to start JACK but it failed
			message = "JACK server failed to start, please check your JACK settings.\n(Is your soundcard ON and plugged in?)";
		var dialog = new Gtk.MessageDialog (new Gtk.Window(), Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK_CANCEL, message);
		var response = dialog.run();
		
		if ( response == Gtk.ResponseType.OK )
		{
			stdout.printf("Attempting to connect to JACK...\t\t\t");
			// Start JACK server, will hop out of loop if opened successfully
			client = Jack.Client.open("ValaClient",Jack.Options.NullOption, out status);
			dialog.destroy();
		}
		else
		{
			stdout.printf("Quitting now.\n");
			dialog.destroy();
			exit(-1);
		}
	}
	
	// here JACK is running, and we can do what we need to
	client.set_process_callback(processCallback);
	stdout.printf("Done!\n"); // connected to JACK
	
	master_l = client.port_register("master_out_L", Jack.DEFAULT_AUDIO_TYPE, Jack.Port.Flags.IsOutput, client.get_buffer_size());
	master_r = client.port_register("master_out_R", Jack.DEFAULT_AUDIO_TYPE, Jack.Port.Flags.IsOutput, client.get_buffer_size());
	
	// register callback
	client.set_process_callback(processCallback);
	
	client.activate();
	// connect ports:
	string[] ports = client.get_ports("", "", Jack.Port.Flags.IsPhysical | Jack.Port.Flags.IsInput);
	client.connect(master_l.name() , ports[0]);
	client.connect(master_r.name() , ports[1]);
	
	// Run GTK
	Gtk.main();
	
	// Take down JACK
	client.deactivate();
	
	return 0;
}
