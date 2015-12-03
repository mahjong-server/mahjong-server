namespace MjaiForms
{
    partial class MainForm
    {
        /// <summary>
        /// 必要なデザイナー変数です。
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// 使用中のリソースをすべてクリーンアップします。
        /// </summary>
        /// <param name="disposing">マネージ リソースが破棄される場合 true、破棄されない場合は false です。</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows フォーム デザイナーで生成されたコード

        /// <summary>
        /// デザイナー サポートに必要なメソッドです。このメソッドの内容を
        /// コード エディターで変更しないでください。
        /// </summary>
        private void InitializeComponent()
        {
            this.debugTextBox = new System.Windows.Forms.TextBox();
            this.hostTextBox = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.label3 = new System.Windows.Forms.Label();
            this.label4 = new System.Windows.Forms.Label();
            this.portTextBox = new System.Windows.Forms.TextBox();
            this.roomTextBox = new System.Windows.Forms.TextBox();
            this.nameTextBox = new System.Windows.Forms.TextBox();
            this.mainBox = new System.Windows.Forms.PictureBox();
            this.connectButton = new System.Windows.Forms.Button();
            this.autoHora = new System.Windows.Forms.CheckBox();
            this.nakiNashi = new System.Windows.Forms.CheckBox();
            this.label5 = new System.Windows.Forms.Label();
            ((System.ComponentModel.ISupportInitialize)(this.mainBox)).BeginInit();
            this.SuspendLayout();
            // 
            // debugTextBox
            // 
            this.debugTextBox.BackColor = System.Drawing.SystemColors.Window;
            this.debugTextBox.Location = new System.Drawing.Point(12, 139);
            this.debugTextBox.Multiline = true;
            this.debugTextBox.Name = "debugTextBox";
            this.debugTextBox.ReadOnly = true;
            this.debugTextBox.ScrollBars = System.Windows.Forms.ScrollBars.Both;
            this.debugTextBox.Size = new System.Drawing.Size(472, 320);
            this.debugTextBox.TabIndex = 0;
            this.debugTextBox.WordWrap = false;
            // 
            // hostTextBox
            // 
            this.hostTextBox.Location = new System.Drawing.Point(56, 11);
            this.hostTextBox.Name = "hostTextBox";
            this.hostTextBox.Size = new System.Drawing.Size(428, 19);
            this.hostTextBox.TabIndex = 1;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("MS UI Gothic", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(128)));
            this.label1.Location = new System.Drawing.Point(13, 10);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(37, 16);
            this.label1.TabIndex = 2;
            this.label1.Text = "host";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Font = new System.Drawing.Font("MS UI Gothic", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(128)));
            this.label2.Location = new System.Drawing.Point(12, 35);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(36, 16);
            this.label2.TabIndex = 3;
            this.label2.Text = "port";
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Font = new System.Drawing.Font("MS UI Gothic", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(128)));
            this.label3.Location = new System.Drawing.Point(12, 61);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(42, 16);
            this.label3.TabIndex = 4;
            this.label3.Text = "room";
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Font = new System.Drawing.Font("MS UI Gothic", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(128)));
            this.label4.Location = new System.Drawing.Point(12, 86);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(44, 16);
            this.label4.TabIndex = 5;
            this.label4.Text = "name";
            // 
            // portTextBox
            // 
            this.portTextBox.Location = new System.Drawing.Point(56, 35);
            this.portTextBox.Name = "portTextBox";
            this.portTextBox.Size = new System.Drawing.Size(428, 19);
            this.portTextBox.TabIndex = 6;
            // 
            // roomTextBox
            // 
            this.roomTextBox.Location = new System.Drawing.Point(56, 60);
            this.roomTextBox.Name = "roomTextBox";
            this.roomTextBox.Size = new System.Drawing.Size(428, 19);
            this.roomTextBox.TabIndex = 7;
            // 
            // nameTextBox
            // 
            this.nameTextBox.Location = new System.Drawing.Point(56, 85);
            this.nameTextBox.Name = "nameTextBox";
            this.nameTextBox.Size = new System.Drawing.Size(428, 19);
            this.nameTextBox.TabIndex = 8;
            // 
            // mainBox
            // 
            this.mainBox.Location = new System.Drawing.Point(503, 10);
            this.mainBox.Name = "mainBox";
            this.mainBox.Size = new System.Drawing.Size(610, 591);
            this.mainBox.TabIndex = 9;
            this.mainBox.TabStop = false;
            this.mainBox.MouseClick += new System.Windows.Forms.MouseEventHandler(this.mainBox_MouseClick);
            this.mainBox.MouseMove += new System.Windows.Forms.MouseEventHandler(this.mainBox_MouseMove);
            // 
            // connectButton
            // 
            this.connectButton.Location = new System.Drawing.Point(409, 110);
            this.connectButton.Name = "connectButton";
            this.connectButton.Size = new System.Drawing.Size(75, 23);
            this.connectButton.TabIndex = 10;
            this.connectButton.Text = "connect";
            this.connectButton.UseVisualStyleBackColor = true;
            this.connectButton.Click += new System.EventHandler(this.button1_Click);
            // 
            // autoHora
            // 
            this.autoHora.AutoSize = true;
            this.autoHora.Location = new System.Drawing.Point(300, 472);
            this.autoHora.Name = "autoHora";
            this.autoHora.Size = new System.Drawing.Size(172, 16);
            this.autoHora.TabIndex = 11;
            this.autoHora.Text = "自動和了（役なしフリテン注意）";
            this.autoHora.UseVisualStyleBackColor = true;
            // 
            // nakiNashi
            // 
            this.nakiNashi.AutoSize = true;
            this.nakiNashi.Location = new System.Drawing.Point(228, 472);
            this.nakiNashi.Name = "nakiNashi";
            this.nakiNashi.Size = new System.Drawing.Size(66, 16);
            this.nakiNashi.TabIndex = 12;
            this.nakiNashi.Text = "鳴き無し";
            this.nakiNashi.UseVisualStyleBackColor = true;
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(39, 473);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(122, 12);
            this.label5.TabIndex = 13;
            this.label5.Text = "右クリック：ツモ切り／パス";
            // 
            // MainForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 12F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1140, 620);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.nakiNashi);
            this.Controls.Add(this.autoHora);
            this.Controls.Add(this.connectButton);
            this.Controls.Add(this.mainBox);
            this.Controls.Add(this.nameTextBox);
            this.Controls.Add(this.roomTextBox);
            this.Controls.Add(this.portTextBox);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.hostTextBox);
            this.Controls.Add(this.debugTextBox);
            this.Name = "MainForm";
            this.Text = "Form1";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.MainForm_FormClosing);
            this.Load += new System.EventHandler(this.Form1_Load);
            ((System.ComponentModel.ISupportInitialize)(this.mainBox)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox debugTextBox;
        private System.Windows.Forms.TextBox hostTextBox;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.TextBox portTextBox;
        private System.Windows.Forms.TextBox roomTextBox;
        private System.Windows.Forms.TextBox nameTextBox;
        private System.Windows.Forms.PictureBox mainBox;
        private System.Windows.Forms.Button connectButton;
        private System.Windows.Forms.CheckBox autoHora;
        private System.Windows.Forms.CheckBox nakiNashi;
        private System.Windows.Forms.Label label5;
    }
}

