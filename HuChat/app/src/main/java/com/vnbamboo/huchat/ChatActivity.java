package com.vnbamboo.huchat;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.support.annotation.Nullable;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.ListView;
import android.widget.TextView;

import com.vnbamboo.huchat.object.ChatMessage;
import com.vnbamboo.huchat.ViewAdapter.ChatMessageListViewAdapter;

import io.socket.emitter.Emitter;

import static com.vnbamboo.huchat.ServiceConnection.mSocket;
import static com.vnbamboo.huchat.ServiceConnection.thisUser;
import static com.vnbamboo.huchat.Utility.CLIENT_REQUEST_HISTORY_CHAT_ROOM;
import static com.vnbamboo.huchat.Utility.CLIENT_SEND_MESSAGE;
import static com.vnbamboo.huchat.Utility.SERVER_SEND_MESSAGE;

public class ChatActivity extends AppCompatActivity {

    String userName;
    String roomCode;
    Intent intent;
    Button btnBack;
    TextView txtUserName;
    Emitter.Listener onNewMessage;
    ChatMessageListViewAdapter chatMessageListViewAdapter;
    ListView lstChatMessage;
    EditText txtMessage;
    ImageButton btnSendMessage;
    Context context = this;

    {
        onNewMessage = new Emitter.Listener() {
            @Override
            public void call( final Object... args ) {
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        ChatMessage chatMessage = new ChatMessage();

                        chatMessage.setRoomCodeReceive((String) args[0]);
                        chatMessage.setUserNameSender((String) args[1]);
                        chatMessage.setContent((String) args[2]);
                        chatMessage.setTime(System.currentTimeMillis());

                        thisUser.getRoomAt(thisUser.getIndexRoomCode((String) args[0])).addMessage(chatMessage);
                        chatMessageListViewAdapter = new ChatMessageListViewAdapter(context, thisUser.getRoomAt(thisUser.getIndexRoomCode((String) args[0])).getChatHistory());
                        lstChatMessage.setAdapter(chatMessageListViewAdapter);
//                        if(!chatMessage.getUserNameSender().toLowerCase().equals(thisUser.getUserName().toLowerCase()))
//                        chatMessageListViewAdapter.add(chatMessage);
                        lstChatMessage.setSelection(lstChatMessage.getCount() - 1);
                    }
                });
            }
        };
    }
    @Override
    protected void onCreate( @Nullable Bundle savedInstanceState ) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_chat);
        getSupportActionBar().hide();
//        final List<ChatMessage> messageList = new ArrayList<>();
//        ChatMessage a = new ChatMessage("", "");
//        messageList.add(a);
        intent = getIntent();
        userName = intent.getStringExtra("RoomName");
        roomCode = intent.getStringExtra("RoomCode");

        new Thread(new Runnable() {
            @Override
            public void run() {
                mSocket.emit(CLIENT_REQUEST_HISTORY_CHAT_ROOM, roomCode);
            }
        }).start();
        try {
            new Thread().sleep(500);
        }catch (Exception e){};

        mSocket.on(SERVER_SEND_MESSAGE, onNewMessage);
        setControl();
        addEvent();
    }

    protected void setControl() {
        btnBack = (Button) findViewById(R.id.btnBack);
        txtUserName = (TextView) findViewById(R.id.txtUserName);
        txtUserName.setText(userName);

        chatMessageListViewAdapter = new ChatMessageListViewAdapter( context, thisUser.getRoomAt(thisUser.getIndexRoomCode(roomCode)).getChatHistory());
        lstChatMessage = (ListView) findViewById(R.id.lstChatMessage);
        lstChatMessage.setAdapter(chatMessageListViewAdapter);
        lstChatMessage.setSelection(lstChatMessage.getCount()-1);
        txtMessage = (EditText) findViewById(R.id.txtMessage);
        btnSendMessage = (ImageButton) findViewById(R.id.btnSendMessage);
    }

    protected void addEvent() {

        btnBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick( View v ) {
                ChatActivity.super.onBackPressed();
            }
        });

        btnSendMessage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick( View v ) {
                if (txtMessage.length() == 0) return;
                ChatMessage a = new ChatMessage(thisUser.getUserName(), txtMessage.getText().toString());

                mSocket.emit(CLIENT_SEND_MESSAGE, roomCode, thisUser.getUserName(), txtMessage.getText().toString());

//                chatMessageListViewAdapter.add(a);
                lstChatMessage.setSelection(lstChatMessage.getCount() - 1);
                txtMessage.setText("");
//                a = new ChatMessage("Rem","Welcome home! Master!");
//                chatMessageListViewAdapter.add(a);
//                lstChatMessage.setSelection(lstChatMessage.getCount()-1);
            }
        });
    }
}
