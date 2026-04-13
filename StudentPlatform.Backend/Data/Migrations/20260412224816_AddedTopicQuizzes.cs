using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StudentPlatform.Backend.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddedTopicQuizzes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_TestQuestions_Topics_TopicId",
                table: "TestQuestions");

            migrationBuilder.DropForeignKey(
                name: "FK_TestResults_Topics_TopicId",
                table: "TestResults");

            migrationBuilder.DropIndex(
                name: "IX_TestResults_TopicId",
                table: "TestResults");

            migrationBuilder.DropIndex(
                name: "IX_TestQuestions_TopicId",
                table: "TestQuestions");

            migrationBuilder.RenameColumn(
                name: "TopicId",
                table: "TestResults",
                newName: "TotalQuestions");

            migrationBuilder.RenameColumn(
                name: "TopicId",
                table: "TestQuestions",
                newName: "QuizId");

            migrationBuilder.AddColumn<int>(
                name: "QuizId",
                table: "TestResults",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "TopicQuizId",
                table: "TestQuestions",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Quizzes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    TopicId = table.Column<int>(type: "INTEGER", nullable: false),
                    Title = table.Column<string>(type: "TEXT", nullable: false),
                    Content = table.Column<string>(type: "TEXT", nullable: false),
                    TimeLimitMinutes = table.Column<int>(type: "INTEGER", nullable: false),
                    ImagePath = table.Column<string>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Quizzes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Quizzes_Topics_TopicId",
                        column: x => x.TopicId,
                        principalTable: "Topics",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TestResults_QuizId",
                table: "TestResults",
                column: "QuizId");

            migrationBuilder.CreateIndex(
                name: "IX_TestQuestions_TopicQuizId",
                table: "TestQuestions",
                column: "TopicQuizId");

            migrationBuilder.CreateIndex(
                name: "IX_Quizzes_TopicId",
                table: "Quizzes",
                column: "TopicId");

            migrationBuilder.AddForeignKey(
                name: "FK_TestQuestions_Quizzes_TopicQuizId",
                table: "TestQuestions",
                column: "TopicQuizId",
                principalTable: "Quizzes",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_TestResults_Quizzes_QuizId",
                table: "TestResults",
                column: "QuizId",
                principalTable: "Quizzes",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_TestQuestions_Quizzes_TopicQuizId",
                table: "TestQuestions");

            migrationBuilder.DropForeignKey(
                name: "FK_TestResults_Quizzes_QuizId",
                table: "TestResults");

            migrationBuilder.DropTable(
                name: "Quizzes");

            migrationBuilder.DropIndex(
                name: "IX_TestResults_QuizId",
                table: "TestResults");

            migrationBuilder.DropIndex(
                name: "IX_TestQuestions_TopicQuizId",
                table: "TestQuestions");

            migrationBuilder.DropColumn(
                name: "QuizId",
                table: "TestResults");

            migrationBuilder.DropColumn(
                name: "TopicQuizId",
                table: "TestQuestions");

            migrationBuilder.RenameColumn(
                name: "TotalQuestions",
                table: "TestResults",
                newName: "TopicId");

            migrationBuilder.RenameColumn(
                name: "QuizId",
                table: "TestQuestions",
                newName: "TopicId");

            migrationBuilder.CreateIndex(
                name: "IX_TestResults_TopicId",
                table: "TestResults",
                column: "TopicId");

            migrationBuilder.CreateIndex(
                name: "IX_TestQuestions_TopicId",
                table: "TestQuestions",
                column: "TopicId");

            migrationBuilder.AddForeignKey(
                name: "FK_TestQuestions_Topics_TopicId",
                table: "TestQuestions",
                column: "TopicId",
                principalTable: "Topics",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_TestResults_Topics_TopicId",
                table: "TestResults",
                column: "TopicId",
                principalTable: "Topics",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
