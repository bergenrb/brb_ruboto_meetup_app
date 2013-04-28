package no.bergenrb.android.ruboto.brb_ruboto_meetup_app;

import android.os.Bundle;

public class BrbRubotoMeetupAppActivity extends org.ruboto.EntryPointActivity {
	public void onCreate(Bundle bundle) {
		getScriptInfo().setRubyClassName(getClass().getSimpleName());
	    super.onCreate(bundle);
	}
}
