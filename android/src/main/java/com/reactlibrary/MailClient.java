package com.reactlibrary;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.ReadableMapKeySetIterator;

import java.security.AccessController;
import java.security.Provider;
import java.security.Security;
import java.util.Date;
import java.util.Properties;
import javax.activation.DataHandler;
import javax.activation.DataSource;
import javax.activation.FileDataSource;

import javax.mail.Message;
import javax.mail.Address;
import javax.mail.Folder;
import javax.mail.Session;
import javax.mail.Store;
import javax.mail.Transport;
import javax.mail.Part;
import javax.mail.BodyPart;
import javax.mail.Multipart;
import javax.mail.PasswordAuthentication;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.List;
import java.util.Arrays;
import java.util.ListIterator;

public class Encoding {
    /** 7-bit encoding. */
    final public static int Encoding7Bit = 0;
    final public static int Encoding8Bit = 1;
    final public static int EncodingBinary = 2;
    final public static int EncodingBase64 = 3;
    final public static int EncodingQuotedPrintable = 4;
    final public static int EncodingOther = 5;
    final public static int EncodingUUEncode = -1;
}


public class IMapClient extends javax.mail.Authenticator {

    public Session imapSession;
	public Store imapStore;
	public Session smtpSession;
	
	static {
        Security.addProvider(new JSSEProvider());
    }

    public void initIMAPSession(UserCredential userCredential,final Promise promise){
        Properties props = new Properties();
		//IMAPS protocol
		props.setProperty("mail.store.protocol", "imaps");
		//Set host address
		props.setProperty("mail.imaps.host", userCredential.getHostname());
		//Set specified port
		props.setProperty("mail.imaps.port", userCredential.getPort());
		//Using SSL
		if (userCredential.getSSL()) {
            props.setProperty("mail.imaps.socketFactory.class", "javax.net.ssl.SSLSocketFactory");
        } else {
            props.setProperty("mail.imaps.starttls.enable", "true");
        }
		props.setProperty("mail.imaps.socketFactory.fallback", "false");
		//Setting IMAP session
		imapSession = Session.getDefaultInstance(props, null);

		try {
			imapStore = imapSession.getStore("imaps");
			//Connect to server by sending username and password.
			//Example mailServer = imap.gmail.com, username = abc, password = abc
			store.connect(userCredential.getHostname(), userCredential.getUsername(), userCredential.getPassword());
			
			WritableMap result = Arguments.createMap();
			result.putString("status", "SUCCESS");
			promise.resolve(result);
		} catch (Exception e) {
			promise.reject("ERROR", e.getMessage());
		}
    }
	
	public void initSMTPSession(UserCredential userCredential,final Promise promise){
		Properties props = new Properties();
        props.setProperty("mail.transport.protocol", "smtp");
        props.setProperty("mail.host", userCredential.getHostname());
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.port", userCredential.getPort());
        props.put("mail.smtp.socketFactory.port", userCredential.getPort());
        if (userCredential.getSSL()) {
            props.put("mail.smtp.socketFactory.class", "javax.net.ssl.SSLSocketFactory");
        } else {
            props.put("mail.smtp.starttls.enable", "true");
        }
        props.put("mail.smtp.socketFactory.fallback", "false");
        props.setProperty("mail.smtp.quitwait", "false");

        smtpSession = Session.getDefaultInstance(props, new javax.mail.Authenticator() {
			protected PasswordAuthentication getPasswordAuthentication() {
				return new PasswordAuthentication(userCredential.getUsername(), userCredential.getPassword());
			}
		});
		
		WritableMap result = Arguments.createMap();
		result.putString("status", "SUCCESS");
		promise.resolve(result);
    }

    public void sendMail(final ReadableMap obj, final Promise promise) {
		try {
			MimeMessage message = new MimeMessage(smtpSession);
			Transport transport = smtpSession.getTransport();
			Multipart _multipart = new MimeMultipart();
			BodyPart messageBodyPart = new MimeBodyPart();
			
			if(obj.hasKey("headers")) {
				ReadableMap headerObj = obj.getMap("headers");
				ReadableMapKeySetIterator headerIterator = headerObj.keySetIterator();
				while (headerIterator.hasNextKey()) {
					String header = headerIterator.nextKey();
					String headerValue = headerObj.getString(header);
					message.addHeader(header, headerValue);
				}
			}
			
			ReadableMap fromObj = obj.getMap("from");
			message.setFrom(new InternetAddress(fromObj.getString("mailbox"), fromObj.getString("addressWithDisplayName")));

			if(obj.hasKey("subject")) {
				message.setSubject(obj.getString("subject"));
			}
			message.setSentDate(new Date());

			if(obj.hasKey("body")) {
				messageBodyPart.setContent(obj.getString("body"), "text/html; charset=utf-8");
			}

			_multipart.addBodyPart(messageBodyPart);
			
			ReadableMap toObj = obj.getMap("to");
			ReadableMapKeySetIterator iterator = toObj.keySetIterator();
			ArrayList<InternetAddress> toAddressList = new ArrayList();
			while (iterator.hasNextKey()) {
				String toMail = iterator.nextKey();
				String toName = toObj.getString(toMail);
				toAddressList.add(new InternetAddress(toMail, toName));
			}

			message.setRecipients(Message.RecipientType.TO, toAddressList.toArray());
			
			if(obj.hasKey("cc")) {
				ReadableMap ccObj = obj.getMap("cc");
				iterator = ccObj.keySetIterator();
				ArrayList<InternetAddress> ccAddressList = new ArrayList();
				while (iterator.hasNextKey()) {
					String ccMail = iterator.nextKey();
					String ccName = ccObj.getString(ccMail);
					ccAddressList.add(new InternetAddress(ccMail, ccName));
				}
				message.setRecipients(Message.RecipientType.CC, ccAddressList.toArray());
			}
			if(obj.hasKey("bcc")) {
				ReadableMap bccObj = obj.getMap("bcc");
				iterator = bccObj.keySetIterator();
				ArrayList<InternetAddress> bccAddressList = new ArrayList();
				while (iterator.hasNextKey()) {
					String bccMail = iterator.nextKey();
					String bccName = bccObj.getString(bccMail);
					bccAddressList.add(new InternetAddress(bccMail, bccName));
				}
				message.addRecipients(Message.RecipientType.BCC, bccAddressList.toArray());
			}
			
			if(obj.hasKey("attachments")) {
				ReadableArray attachments = obj.getArray("attachments");
				for (int i = 0; i < attachments.size(); i++) {
					File file = new File(attachments.getString(i));
					messageBodyPart = new MimeBodyPart();
					DataSource source = new FileDataSource(file);
					
					messageBodyPart.setDataHandler(new DataHandler(source));
					messageBodyPart.setFileName(file.getName());
					if (source.getContentType().split("/")[0].equals("image")) {
						messageBodyPart.setHeader("Content-ID", "<image>");
					}
					_multipart.addBodyPart(messageBodyPart);
				}
			}

			message.setContent(_multipart);
			message.saveChanges();

			transport.send(message);
			transport.close();
			
			WritableMap success = new WritableNativeMap();
			success.putString("status", "SUCCESS");
			promise.resolve(success);
		} catch (Exception e) {
			promise.reject("ERROR", e.getMessage());
		}
    }

    public void getMail(final ReadableMap obj,final Promise promise) {
        final String folder = obj.getString("folder");
        int messageId = obj.getInt("messageId"); 
        int requestKind = obj.getInt("requestKind");
		
		try {
			Folder fd = store.getFolder(folder);
			fd.open(Folder.READ_ONLY);
			Message message = fd.getMessage(messageId);
			
			WritableMap mailData = Arguments.createMap();
			final Long uid = message.getMessageNumber();
			mailData.putInt("id", uid.intValue());
			mailData.putString("date", message.getReceivedDate().toString());
			WritableMap fromData = Arguments.createMap();
			InternetAddress address = (InternetAddress)message.getFrom()[0];
			fromData.putString("mailbox", address.getAddress());
			mailData.putInt("flags", message.getFlags().hashCode());
			fromData.putString("displayName", address.getPersonal());
			mailData.putMap("from", fromData);
			WritableMap toData = Arguments.createMap();
			Address[] toIterator = message.getRecipients(Message.RecipientType.TO);
			for (int i = 0; i < toIterator.lenght; i++) {
				InternetAddress toAddress = (InternetAddress)toIterator[i];
				toData.putString(toAddress.getAddress(), toAddress.getPersonal());
			}
			mailData.putMap("to", toData);
			Address[] ccIterator = message.getRecipients(Message.RecipientType.CC);
			if(ccIterator.lenght) {
				WritableMap ccData = Arguments.createMap();
				for (int i = 0; i < ccIterator.lenght; i++) {
					InternetAddress ccAddress = (InternetAddress)ccIterator[i];
					ccData.putString(ccAddress.getAddress(), ccAddress.getPersonal());
				}
				mailData.putMap("cc", ccData);
			}
			Address[] bccIterator = message.getRecipients(Message.RecipientType.BCC);
			if(bccIterator.lenght) {
				WritableMap bccData = Arguments.createMap();
				for (int i = 0; i < bccIterator.lenght; i++) {
					InternetAddress bccAddress = (InternetAddress)bccIterator[i];
					bccData.putString(bccAddress.getAddress(), bccAddress.getPersonal());
				}
				mailData.putMap("bcc", bccData);
			}
			mailData.putString("subject", message.getSubject());
			Part body = getBodyPart(message)
			mailData.putString("body", (String) body.getContent());
			WritableMap attachmentsData = Arguments.createMap();
			
			if (message.getContentType().contains("multipart")) {
				Multipart multiPart = (Multipart) message.getContent();

				for (int i = 0; i < multiPart.getCount(); i++) {
					MimeBodyPart part = (MimeBodyPart) multiPart.getBodyPart(i);
					if (Part.ATTACHMENT.equalsIgnoreCase(part.getDisposition())) {
						WritableMap attachmentData = Arguments.createMap();
						attachmentData.putString("filename", part.getFileName());
						Long size = part.getSize();
						attachmentData.putString("size", size.toString());
						String enc = part.getEncoding().toLowerCase();
						Integer encoding =  enc.equals("7bit") ? Encoding.Encoding7Bit :
							(enc.equals("8bit") ? Encoding.Encoding8Bit :
							(enc.equals("binary") ? Encoding.EncodingBinary : 
							(enc.equals("base64") ? Encoding.EncodingBase64 : 
							(enc.equals("quoted-printable") ? Encoding.EncodingQuotedPrintable : 
							(enc.equals("uuencode") ? Encoding.EncodingUUEncode : 0)))));
						attachmentData.putInt("encoding", encoding);
						attachmentsData.putMap(part.partID(), attachmentData);
					}
				}
			}
			List<AbstractPart> attachments = message.attachments();
			if (!attachments.isEmpty()) {
				for (AbstractPart attachment: message.attachments()) {
					IMAPPart part = (IMAPPart) attachment;
					WritableMap attachmentData = Arguments.createMap();
					attachmentData.putString("filename", attachment.filename());
					Long size = part.size();
					attachmentData.putString("size", size.toString());
					attachmentData.putInt("encoding", part.encoding());
					attachmentsData.putMap(part.partID(), attachmentData);
				}
			}
			mailData.putMap("attachments", attachmentsData);

			WritableMap headerData = Arguments.createMap();
			ListIterator<String> headerIterator = message.header().allExtraHeadersNames().listIterator();
			while(headerIterator.hasNext()){
				String headerKey = headerIterator.next();
				headerData.putString(headerKey, message.header().extraHeaderValueForName(headerKey));
			}
			mailData.putMap("headers", headerData);

			mailData.putString("status", "success");
			promise.resolve(mailData);
			
			fd.close();
		} catch (Exception e) {
			promise.reject(e.getMessage());
			return;
		}
    }

    public void createFolderLabel(final ReadableMap obj,final Promise promise) {
        IMAPOperation imapOperation = this.imapSession.createFolderOperation(obj.getString("folder"));
        imapOperation.start(new OperationCallback() {
            @Override
            public void succeeded() {
                WritableMap result = Arguments.createMap();
                result.putString("status", "SUCCESS");
                promise.resolve(result);
            }
            @Override
            public void failed(MailException e) {
                promise.reject(String.valueOf(e.errorCode()), e.getMessage());
            }
        });
    }

    public void renameFolderLabel(final ReadableMap obj,final Promise promise) {
        IMAPOperation imapOperation = this.imapSession.renameFolderOperation(obj.getString("folderOldName"),obj.getString("folderNewName"));
        imapOperation.start(new OperationCallback() {
            @Override
            public void succeeded() {
                WritableMap result = Arguments.createMap();
                result.putString("status", "SUCCESS");
                promise.resolve(result);
            }
            @Override
            public void failed(MailException e) {
                promise.reject(String.valueOf(e.errorCode()), e.getMessage());
            }
        });
    }

    public void deleteFolderLabel(final ReadableMap obj,final Promise promise) {
        IMAPOperation imapOperation = this.imapSession.deleteFolderOperation(obj.getString("folder"));
        imapOperation.start(new OperationCallback() {
            @Override
            public void succeeded() {
                WritableMap result = Arguments.createMap();
                result.putString("status", "SUCCESS");
                promise.resolve(result);
            }
            @Override
            public void failed(MailException e) {
                promise.reject(String.valueOf(e.errorCode()), e.getMessage());
            }
        });
    }

    public void getFolders(final Promise promise) {
        final IMAPFetchFoldersOperation foldersOperation = imapSession.fetchAllFoldersOperation();
        foldersOperation.start(new OperationCallback() {
            @Override
            public void succeeded() {
                List<IMAPFolder> folders = foldersOperation.folders();
                WritableMap result = Arguments.createMap();
                WritableArray a = new WritableNativeArray();
                result.putString("status", "SUCCESS");
                for (IMAPFolder folder : folders) {
                    WritableMap mapFolder = Arguments.createMap();
                        mapFolder.putString("path",folder.path());
                        mapFolder.putInt("flags", folder.flags());
                        a.pushMap(mapFolder);    
                }
                result.putArray("folders",a);
                promise.resolve(result);
            }
            @Override
            public void failed(MailException e) {
                promise.reject(String.valueOf(e.errorCode()), e.getMessage());
            }
        });
    }

    public void moveEmail(final ReadableMap obj, final Promise promise) {
        String from = obj.getString("folderFrom");
        int messageId = obj.getInt("messageId");
        String to = obj.getString("folderTo");
        IMAPOperation imapOperation = imapSession.copyMessagesOperation(from,IndexSet.indexSetWithIndex(messageId),to);
        imapOperation.start(new OperationCallback() {
            @Override
            public void succeeded() {
            }
            @Override
            public void failed(MailException e) {
                promise.reject(String.valueOf(e.errorCode()), e.getMessage());
            }
        });
        permantDelete(obj,promise);
    }

    public void permantDelete(final ReadableMap obj, final Promise promise) {
        String folder = obj.getString("folderFrom");
        int messageId = obj.getInt("messageId");
        IMAPOperation imapOperation = imapSession.storeFlagsByUIDOperation(folder,IndexSet.indexSetWithIndex(messageId), 0, MessageFlag.MessageFlagDeleted);
        imapOperation.start(new OperationCallback() {
            @Override
            public void succeeded() {
            }
            @Override
            public void failed(MailException e) {
                promise.reject(String.valueOf(e.errorCode()), e.getMessage());
            }
        });
        imapOperation = imapSession.expungeOperation(folder);
        imapOperation.start(new OperationCallback() {
            @Override
            public void succeeded() {
                WritableMap result = Arguments.createMap();
                result.putString("status", "SUCCESS");
                promise.resolve(result);
            }
            @Override
            public void failed(MailException e) {
                promise.reject(String.valueOf(e.errorCode()), e.getMessage());
            }
        });
    }

    public void ActionLabelMessage(final ReadableMap obj, final Promise promise) {
        String folder = obj.getString("folder");
        int messageId = obj.getInt("messageId");
        int flag = obj.getInt("flagsRequestKind");
        ReadableArray listTags = obj.getArray("tags");
        List<String> tags = new ArrayList<String>();
        for (int i = 0; i < listTags.size(); i++) {
            tags.add(listTags.getString(i));
        }
        IMAPOperation imapOperation = imapSession.storeLabelsByUIDOperation(folder, IndexSet.indexSetWithIndex(messageId), flag, tags);
        imapOperation.start(new OperationCallback() {
            @Override
            public void succeeded() {
                WritableMap result = Arguments.createMap();
                result.putString("status", "SUCCESS");
                promise.resolve(result);
            }
            @Override
            public void failed(MailException e) {
                promise.reject(String.valueOf(e.errorCode()), e.getMessage());
            }
        });
    }

    public void ActionFlagMessage(final ReadableMap obj, final Promise promise) {
        String folder = obj.getString("folder");
        int messageId = obj.getInt("messageId");
        int flag = obj.getInt("flagsRequestKind");
        int messageFlag = obj.getInt("messageFlag");
        
        IMAPOperation imapOperation = imapSession.storeFlagsByUIDOperation(folder,IndexSet.indexSetWithIndex(messageId), flag, messageFlag);
        imapOperation.start(new OperationCallback() {
            @Override
            public void succeeded() {
                WritableMap result = Arguments.createMap();
                result.putString("status", "SUCCESS");
                promise.resolve(result);
            }
            @Override
            public void failed(MailException e) {
                promise.reject(String.valueOf(e.errorCode()), e.getMessage());
            }
        }); 
    }

    public void getMails(final ReadableMap obj, final Promise promise) {
        final String folder = obj.getString("folder");
        int requestKind = obj.getInt("requestKind");
        IndexSet indexSet = IndexSet.indexSetWithRange(new Range(1, Long.MAX_VALUE));
        final IMAPFetchMessagesOperation messagesOperation = imapSession.fetchMessagesByUIDOperation(folder, requestKind, indexSet);

        if (obj.hasKey("headers")) {
            ReadableArray headersArray = obj.getArray("headers");
            List<String> extraHeaders = new ArrayList<>();
            for (int i = 0; headersArray.size() > i; i++) {
                extraHeaders.add(headersArray.getString(i));
            }
            messagesOperation.setExtraHeaders(extraHeaders);
        }

        final WritableMap result = Arguments.createMap();
        final WritableArray mails = Arguments.createArray();
        messagesOperation.start(new OperationCallback() {
            @Override
            public void succeeded() {
                List<IMAPMessage> messages = messagesOperation.messages();
                if (messages.isEmpty()) {
                    promise.reject("Mails not found!");
                    return;
                }
                for (final IMAPMessage message: messages) {
                    final WritableMap mailData = Arguments.createMap();
                    WritableMap headerData = Arguments.createMap();
                    ListIterator<String> headerIterator = message.header().allExtraHeadersNames().listIterator();
                    while(headerIterator.hasNext()){
                        String headerKey = headerIterator.next();
                        headerData.putString(headerKey, message.header().extraHeaderValueForName(headerKey));
                    }
                    mailData.putMap("headers", headerData);
                    Long mailId = message.uid();
                    mailData.putInt("id", mailId.intValue());
                    mailData.putInt("flags", message.flags());
                    mailData.putString("from", message.header().from().displayName());
                    mailData.putString("subject", message.header().subject());
                    mailData.putString("date", message.header().date().toString());
                    mailData.putInt("attachments", message.attachments().size());
                    
                    mails.pushMap(mailData);              
                }
                result.putString("status", "SUCCESS");
                result.putArray("mails", mails);
                promise.resolve(result);
            }
            @Override
            public void failed(MailException e) {
                promise.reject(String.valueOf(e.errorCode()), e.getMessage());
            }
        });
    }


    public void getAttachment(final ReadableMap obj, final Promise promise) {
        final String filename = obj.getString("filename");
        String folderId = obj.getString("folder");
        long messageId = (long) obj.getInt("messageId");
        String partID = obj.getString("partID");
        int encoding = obj.getInt("encoding");
        final String folderOutput = obj.getString("folderOutput");
        final IMAPFetchContentOperation imapOperation = imapSession.fetchMessageAttachmentByUIDOperation(folderId, messageId, partID,encoding,true);
        imapOperation.start(new OperationCallback() {
            @Override
            public void succeeded() {
                File file = new File(folderOutput, filename);
                try {
                    FileOutputStream outputStream;
                    outputStream = new FileOutputStream(file);
                    outputStream.write(imapOperation.data());
                    outputStream.close();
                    if(file.canWrite()) {
                        WritableMap result = Arguments.createMap();
                        result.putString("status", "SUCCESS");
                        promise.resolve(result);
                    }
                } catch (FileNotFoundException e) {
                    promise.reject(e.getMessage());
                } catch (IOException e) {
                    promise.reject(e.getMessage());
                } catch (Exception e) {
                    promise.reject(e.getMessage());
                }
            }
            @Override
            public void failed(MailException e) {
                promise.reject(String.valueOf(e.errorCode()), e.getMessage());
            }
        });
    }

	/**
     * Return the primary text content of the message.
     */
    private Part getBodyPart(Part p) throws MessagingException, IOException {
        if (p.isMimeType("text/*")) {
            return p;
        }

        if (p.isMimeType("multipart/alternative")) {
            // prefer html text over plain text
            Multipart mp = (Multipart)p.getContent();
            Part body = null;
            for (int i = 0; i < mp.getCount(); i++) {
                Part bp = mp.getBodyPart(i);
                if (bp.isMimeType("text/plain")) {
                    if (body == null)
                        body = getBodyPart(bp);
                    continue;
                } else if (bp.isMimeType("text/html")) {
                    Part pt = getBodyPart(bp);
                    if (pt != null)
                        return pt;
                } else {
                    return getBodyPart(bp);
                }
            }
            return body;
        } else if (p.isMimeType("multipart/*")) {
            Multipart mp = (Multipart)p.getContent();
            for (int i = 0; i < mp.getCount(); i++) {
                Part pt = getBodyPart(mp.getBodyPart(i));
                if (pt != null)
                    return pt;
            }
        }

        return null;
    }
    
}

class JSSEProvider extends Provider {

    private static final long serialVersionUID = 1L;

    public JSSEProvider() {
        super("HarmonyJSSE", 1.0, "Harmony JSSE Provider");
        AccessController.doPrivileged(new java.security.PrivilegedAction<Void>() {
            public Void run() {
                put("SSLContext.TLS",
                      "org.apache.harmony.xnet.provider.jsse.SSLContextImpl");
                put("Alg.Alias.SSLContext.TLSv1", "TLS");
                put("KeyManagerFactory.X509",
                      "org.apache.harmony.xnet.provider.jsse.KeyManagerFactoryImpl");
                put("TrustManagerFactory.X509",
                      "org.apache.harmony.xnet.provider.jsse.TrustManagerFactoryImpl");
                return null;
            }
        });
    }
}